require "rails_helper"

RSpec.describe Incident, type: :model do
  before { allow(IncidentNotificationJob).to receive(:perform_later) }

  describe "associations" do
    it { is_expected.to belong_to(:uptime_monitor) }
    it { is_expected.to have_many(:updates).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:incident) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:started_at) }
  end

  describe "constants" do
    it "defines STATUSES" do
      expect(Incident::STATUSES).to eq(%w[investigating identified monitoring resolved])
    end

    it "defines SEVERITIES" do
      expect(Incident::SEVERITIES).to eq(%w[minor major critical])
    end
  end

  describe "scopes" do
    let(:monitor) { create(:uptime_monitor) }
    let!(:active_incident)   { create(:incident, :investigating, uptime_monitor: monitor) }
    let!(:identified_incident) { create(:incident, :identified,  uptime_monitor: monitor) }
    let!(:resolved_incident) { create(:incident, :resolved,     uptime_monitor: monitor) }

    describe ".active" do
      it "includes investigating and identified" do
        active = Incident.active
        expect(active).to include(active_incident, identified_incident)
        expect(active).not_to include(resolved_incident)
      end
    end

    describe ".resolved" do
      it "returns only resolved incidents" do
        expect(Incident.resolved).to include(resolved_incident)
        expect(Incident.resolved).not_to include(active_incident)
      end
    end

    describe ".recent" do
      it "orders by started_at descending" do
        older = create(:incident, uptime_monitor: monitor, started_at: 2.hours.ago)
        ordered = Incident.recent.to_a
        expect(ordered.first.started_at).to be >= ordered.last.started_at
      end
    end
  end

  describe "after_create callbacks" do
    it "creates an initial 'investigating' update" do
      monitor = create(:uptime_monitor)
      incident = create(:incident, uptime_monitor: monitor)
      expect(incident.updates.count).to eq(1)
      expect(incident.updates.first.status).to eq("investigating")
      expect(incident.updates.first.created_by).to eq("system")
    end

    it "schedules a notification job" do
      monitor = create(:uptime_monitor)
      incident = create(:incident, uptime_monitor: monitor)
      expect(IncidentNotificationJob).to have_received(:perform_later).with(incident.id, "created")
    end
  end

  describe "#resolve!" do
    let(:incident) do
      monitor = create(:uptime_monitor)
      create(:incident, uptime_monitor: monitor, started_at: 2.hours.ago)
    end

    it "sets status to resolved" do
      incident.resolve!(notes: "Fixed by patching DB")
      expect(incident.reload.status).to eq("resolved")
    end

    it "records resolved_at and duration_seconds" do
      Timecop.freeze do
        incident.resolve!
        expect(incident.reload.resolved_at).to be_within(2.seconds).of(Time.current)
        expect(incident.duration_seconds).to be > 0
      end
    end

    it "stores resolution notes" do
      incident.resolve!(notes: "Hotfix deployed")
      expect(incident.reload.resolution_notes).to eq("Hotfix deployed")
    end

    it "adds a resolved update entry" do
      incident.resolve!(notes: "Done")
      resolved_update = incident.updates.reload.find { |u| u.status == "resolved" }
      expect(resolved_update).to be_present
    end
  end

  describe "#add_update" do
    let(:incident) do
      monitor = create(:uptime_monitor)
      create(:incident, uptime_monitor: monitor)
    end

    it "creates an IncidentUpdate record" do
      expect {
        incident.add_update("identified", "Root cause found", user: "ops@example.com")
      }.to change { incident.updates.count }.by(1)
    end

    it "updates the incident status" do
      incident.add_update("monitoring", "Fix deployed")
      expect(incident.reload.status).to eq("monitoring")
    end
  end

  describe "#duration" do
    it "returns seconds since started_at for active incidents" do
      monitor = create(:uptime_monitor)
      incident = create(:incident, uptime_monitor: monitor, started_at: 1.hour.ago)
      expect(incident.duration).to be_within(5).of(3600)
    end

    it "returns resolved_at - started_at for resolved incidents" do
      monitor = create(:uptime_monitor)
      incident = create(:incident, :resolved,
                        uptime_monitor: monitor,
                        started_at: 2.hours.ago,
                        resolved_at: 1.hour.ago,
                        duration_seconds: 3600)
      expect(incident.duration).to be_within(5).of(3600)
    end
  end

  describe "#duration_humanized" do
    let(:monitor) { create(:uptime_monitor) }

    it "formats hours and minutes" do
      incident = create(:incident, uptime_monitor: monitor,
                        started_at: 2.hours.ago + 30.minutes,
                        resolved_at: Time.current, status: "resolved")
      incident.update_columns(resolved_at: Time.current)
      expect(incident.duration_humanized).to include("h")
    end

    it "returns 0s for zero duration" do
      incident = build(:incident, started_at: Time.current)
      allow(incident).to receive(:duration).and_return(0)
      expect(incident.duration_humanized).to eq("0s")
    end
  end

  describe "#active? and #resolved?" do
    let(:monitor) { create(:uptime_monitor) }

    it "returns active? true for non-resolved incidents" do
      incident = create(:incident, :investigating, uptime_monitor: monitor)
      expect(incident.active?).to be true
      expect(incident.resolved?).to be false
    end

    it "returns resolved? true for resolved incidents" do
      incident = create(:incident, :resolved, uptime_monitor: monitor)
      expect(incident.resolved?).to be true
      expect(incident.active?).to be false
    end
  end
end
