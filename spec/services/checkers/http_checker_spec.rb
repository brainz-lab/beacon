require "rails_helper"

RSpec.describe Checkers::HTTPChecker, type: :service do
  let(:monitor) { create(:uptime_monitor, :http, url: "https://example.com", expected_status: 200) }
  subject(:checker) { described_class.new(monitor, region: "us-east-1") }

  describe "#check" do
    context "when the endpoint responds with expected status" do
      before do
        stub_request(:get, "https://example.com")
          .to_return(status: 200, body: "OK", headers: {})
      end

      it "returns a CheckResult with status up" do
        result = checker.check
        expect(result).to be_a(CheckResult)
        expect(result.status).to eq("up")
      end

      it "records response_time_ms" do
        result = checker.check
        expect(result.response_time_ms).to be > 0
      end

      it "records the status_code" do
        result = checker.check
        expect(result.status_code).to eq(200)
      end
    end

    context "when the endpoint returns an unexpected status" do
      before do
        stub_request(:get, "https://example.com").to_return(status: 503)
      end

      it "returns a CheckResult with status down" do
        result = checker.check
        expect(result.status).to eq("down")
      end
    end

    context "on timeout" do
      before do
        stub_request(:get, "https://example.com").to_timeout
      end

      it "returns a CheckResult with status down and timeout error_type" do
        result = checker.check
        expect(result.status).to eq("down")
        expect(result.error_type).to eq("timeout")
      end
    end

    context "when expected_body is set" do
      let(:monitor) do
        create(:uptime_monitor, :http, url: "https://example.com",
               expected_status: 200, expected_body: "healthy")
      end

      it "succeeds when the body contains the expected string" do
        stub_request(:get, "https://example.com").to_return(status: 200, body: "Service is healthy")
        result = checker.check
        expect(result.status).to eq("up")
      end

      it "fails when the body does not contain the expected string" do
        stub_request(:get, "https://example.com").to_return(status: 200, body: "Service is down")
        result = checker.check
        expect(result.status).to eq("down")
      end
    end
  end
end
