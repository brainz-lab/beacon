require "rails_helper"

RSpec.describe CheckResult, type: :model, timescaledb: true do
  describe "associations" do
    it { is_expected.to belong_to(:uptime_monitor) }
  end

  describe "validations" do
    subject { build(:check_result) }

    it { is_expected.to validate_presence_of(:checked_at) }
    it { is_expected.to validate_presence_of(:region) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "scopes" do
    let(:monitor) { create(:uptime_monitor) }
    let!(:up_result)   { create(:check_result, :up,   uptime_monitor: monitor, checked_at: 1.hour.ago) }
    let!(:down_result) { create(:check_result, :down, uptime_monitor: monitor, checked_at: 30.minutes.ago) }
    let!(:eu_result)   { create(:check_result, :up,   uptime_monitor: monitor, region: "eu-west-1", checked_at: 10.minutes.ago) }

    describe ".recent" do
      it "orders by checked_at descending" do
        ordered = monitor.check_results.recent.to_a
        expect(ordered.first.checked_at).to be >= ordered.last.checked_at
      end
    end

    describe ".successful" do
      it "returns only up status results" do
        expect(monitor.check_results.successful).to include(up_result, eu_result)
        expect(monitor.check_results.successful).not_to include(down_result)
      end
    end

    describe ".failed" do
      it "returns only down status results" do
        expect(monitor.check_results.failed).to include(down_result)
        expect(monitor.check_results.failed).not_to include(up_result)
      end
    end

    describe ".in_region" do
      it "filters by region" do
        eu_results = monitor.check_results.in_region("eu-west-1")
        expect(eu_results).to include(eu_result)
        expect(eu_results).not_to include(up_result)
      end
    end

    describe ".since" do
      it "returns checks after the given time" do
        recent = monitor.check_results.since(45.minutes.ago)
        expect(recent).to include(down_result, eu_result)
        expect(recent).not_to include(up_result)
      end
    end
  end

  describe "#success?" do
    it "returns true when status is up" do
      result = build(:check_result, :up)
      expect(result.success?).to be true
    end

    it "returns false when status is down" do
      result = build(:check_result, :down)
      expect(result.success?).to be false
    end
  end

  describe "#failed?" do
    it "returns true when status is down" do
      result = build(:check_result, :down)
      expect(result.failed?).to be true
    end

    it "returns false when status is up" do
      result = build(:check_result, :up)
      expect(result.failed?).to be false
    end
  end

  describe "#timing_breakdown" do
    it "returns a hash of timing components" do
      result = build(:check_result,
                     dns_time_ms: 10,
                     connect_time_ms: 20,
                     tls_time_ms: 15,
                     ttfb_ms: 50,
                     response_time_ms: 120)
      breakdown = result.timing_breakdown
      expect(breakdown[:dns]).to eq(10)
      expect(breakdown[:connect]).to eq(20)
      expect(breakdown[:tls]).to eq(15)
      expect(breakdown[:ttfb]).to eq(50)
      expect(breakdown[:total]).to eq(120)
    end

    it "omits nil values" do
      result = build(:check_result, dns_time_ms: nil, response_time_ms: 100)
      expect(result.timing_breakdown).not_to have_key(:dns)
      expect(result.timing_breakdown).to have_key(:total)
    end
  end

  describe "#error_description" do
    it "returns human-readable message for known error types" do
      {
        "timeout"            => "Request timed out",
        "dns_error"          => "DNS resolution failed",
        "ssl_error"          => "SSL/TLS error",
        "connection_refused" => "Connection refused",
        "ping_failed"        => "Host unreachable"
      }.each do |type, description|
        result = build(:check_result, error_type: type, error_message: "raw error")
        expect(result.error_description).to eq(description)
      end
    end

    it "falls back to error_message for unknown error types" do
      result = build(:check_result, error_type: "unknown_type", error_message: "Something went wrong")
      expect(result.error_description).to eq("Something went wrong")
    end
  end
end
