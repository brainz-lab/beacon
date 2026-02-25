require "rails_helper"

RSpec.describe Checkers::TCPChecker, type: :service do
  let(:monitor) { create(:uptime_monitor, :tcp, host: "db.example.com", port: 5432, timeout_seconds: 5) }
  subject(:checker) { described_class.new(monitor, region: "us-east-1") }

  describe "#check" do
    it "returns a successful CheckResult when TCP connection succeeds" do
      allow(Socket).to receive(:tcp).and_yield(double("socket"))

      result = checker.check
      expect(result.status).to eq("up")
      expect(result.response_time_ms).to be > 0
    end

    it "returns a failed CheckResult on connection refused" do
      allow(Socket).to receive(:tcp).and_raise(Errno::ECONNREFUSED)

      result = checker.check
      expect(result.status).to eq("down")
      expect(result.error_type).to eq("connection_refused")
    end

    it "returns a failed CheckResult on host unreachable" do
      allow(Socket).to receive(:tcp).and_raise(Errno::ETIMEDOUT)

      result = checker.check
      expect(result.status).to eq("down")
    end
  end
end
