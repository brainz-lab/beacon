require "rails_helper"

RSpec.describe UptimeMonitor, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:check_results).dependent(:destroy) }
    it { is_expected.to have_many(:incidents).dependent(:destroy) }
    it { is_expected.to have_many(:status_page_monitors).dependent(:destroy) }
    it { is_expected.to have_many(:status_pages).through(:status_page_monitors) }
    it { is_expected.to have_many(:alert_rules).dependent(:destroy) }
    it { is_expected.to have_one(:ssl_certificate).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:uptime_monitor) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:monitor_type) }
    it { is_expected.to validate_inclusion_of(:monitor_type).in_array(%w[http tcp dns ssl ping]) }
    it { is_expected.to validate_numericality_of(:interval_seconds).is_greater_than_or_equal_to(30) }

    it "requires url for http type" do
      monitor = build(:uptime_monitor, :http, url: nil)
      expect(monitor).not_to be_valid
      expect(monitor.errors[:url]).to be_present
    end

    it "requires url for ssl type" do
      monitor = build(:uptime_monitor, :ssl, url: nil)
      expect(monitor).not_to be_valid
    end

    it "requires host for tcp type" do
      monitor = build(:uptime_monitor, :tcp, host: nil)
      expect(monitor).not_to be_valid
    end

    it "requires host for dns type" do
      monitor = build(:uptime_monitor, :dns, host: nil)
      expect(monitor).not_to be_valid
    end

    it "requires port for tcp type" do
      monitor = build(:uptime_monitor, :tcp, port: nil)
      expect(monitor).not_to be_valid
    end
  end

  describe "scopes" do
    let(:project) { create(:project) }
    let!(:enabled_monitor)  { create(:uptime_monitor, :up,      project: project, enabled: true, paused: false) }
    let!(:paused_monitor)   { create(:uptime_monitor, :paused,  project: project, enabled: true) }
    let!(:disabled_monitor) { create(:uptime_monitor, :disabled, project: project) }
    let!(:down_monitor)     { create(:uptime_monitor, :down,    project: project) }
    let!(:degraded_monitor) { create(:uptime_monitor, :degraded, project: project) }

    describe ".enabled" do
      it "returns only enabled and unpaused monitors" do
        enabled = project.uptime_monitors.enabled
        expect(enabled).to include(enabled_monitor)
        expect(enabled).not_to include(paused_monitor, disabled_monitor)
      end
    end

    describe ".paused" do
      it "returns only paused monitors" do
        expect(project.uptime_monitors.paused).to include(paused_monitor)
        expect(project.uptime_monitors.paused).not_to include(enabled_monitor)
      end
    end

    describe ".up / .down / .degraded" do
      it "filters by status" do
        expect(project.uptime_monitors.up).to include(enabled_monitor)
        expect(project.uptime_monitors.down).to include(down_monitor)
        expect(project.uptime_monitors.degraded).to include(degraded_monitor)
      end
    end

    describe ".by_status" do
      it "filters by given status string" do
        expect(project.uptime_monitors.by_status("down")).to include(down_monitor)
        expect(project.uptime_monitors.by_status("down")).not_to include(enabled_monitor)
      end
    end
  end

  describe "#target" do
    it "returns url for http monitors" do
      monitor = build(:uptime_monitor, :http, url: "https://api.example.com")
      expect(monitor.target).to eq("https://api.example.com")
    end

    it "returns host:port for tcp monitors" do
      monitor = build(:uptime_monitor, :tcp, host: "db.example.com", port: 5432)
      expect(monitor.target).to eq("db.example.com:5432")
    end
  end

  describe "#uptime" do
    let(:monitor) { create(:uptime_monitor) }

    it "delegates to UptimeCalculator" do
      calculator = instance_double(UptimeCalculator, calculate: 99.5)
      allow(UptimeCalculator).to receive(:new).with(monitor, period: 30.days).and_return(calculator)

      result = monitor.uptime(period: 30.days)
      expect(result).to eq(99.5)
    end
  end

  describe "#average_response_time" do
    let(:monitor) { create(:uptime_monitor) }

    it "returns 0 when no checks exist" do
      expect(monitor.average_response_time).to eq(0)
    end
  end

  describe "#active_incident" do
    let(:monitor) { create(:uptime_monitor) }

    it "returns nil when no active incidents" do
      expect(monitor.active_incident).to be_nil
    end

    it "returns the most recent active incident" do
      allow(IncidentNotificationJob).to receive(:perform_later)
      incident = create(:incident, uptime_monitor: monitor, status: "investigating")
      expect(monitor.active_incident).to eq(incident)
    end
  end

  describe "#checker_class" do
    it "returns HTTPChecker for http" do
      m = build(:uptime_monitor, :http)
      expect(m.send(:checker_class)).to eq(Checkers::HTTPChecker)
    end

    it "returns TCPChecker for tcp" do
      m = build(:uptime_monitor, :tcp)
      expect(m.send(:checker_class)).to eq(Checkers::TCPChecker)
    end

    it "returns DNSChecker for dns" do
      m = build(:uptime_monitor, :dns)
      expect(m.send(:checker_class)).to eq(Checkers::DNSChecker)
    end

    it "returns SSLChecker for ssl" do
      m = build(:uptime_monitor, :ssl)
      expect(m.send(:checker_class)).to eq(Checkers::SSLChecker)
    end

    it "returns PingChecker for ping" do
      m = build(:uptime_monitor, :ping)
      expect(m.send(:checker_class)).to eq(Checkers::PingChecker)
    end
  end
end
