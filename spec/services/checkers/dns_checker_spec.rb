require "rails_helper"

RSpec.describe Checkers::DNSChecker, type: :service do
  let(:monitor) { create(:uptime_monitor, :dns, host: "example.com", timeout_seconds: 5) }
  subject(:checker) { described_class.new(monitor, region: "us-east-1") }

  describe "#check" do
    it "returns a successful CheckResult when DNS resolves" do
      mock_dns = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(mock_dns)
      allow(mock_dns).to receive(:getaddress).with("example.com").and_return("93.184.216.34")
      allow(mock_dns).to receive(:getaddresses).with("example.com").and_return(["93.184.216.34"])
      allow(mock_dns).to receive(:close)

      result = checker.check
      expect(result.status).to eq("up")
      expect(result.resolved_ip).to be_present
    end

    it "returns a failed CheckResult when DNS resolution fails" do
      allow(Resolv::DNS).to receive(:new).and_raise(Resolv::ResolvError)

      result = checker.check
      expect(result.status).to eq("down")
      expect(result.error_type).to eq("dns_error")
    end
  end
end
