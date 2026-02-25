require "rails_helper"

RSpec.describe SignalClient, type: :service do
  let(:signal_url) { "http://signal:4005" }
  let(:api_key)    { "sk_test_signal_master" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).with("SIGNAL_URL", anything).and_return(signal_url)
    allow(ENV).to receive(:[]).with("SIGNAL_MASTER_KEY").and_return(api_key)
    allow(ENV).to receive(:[]).with("SIGNAL_URL").and_return(signal_url)
    # Reset memoized connection
    SignalClient.instance_variable_set(:@connection, nil)
  end

  describe ".enabled?" do
    it "returns true when both SIGNAL_URL and SIGNAL_MASTER_KEY are set" do
      expect(SignalClient.enabled?).to be true
    end

    it "returns false when SIGNAL_MASTER_KEY is blank" do
      allow(ENV).to receive(:[]).with("SIGNAL_MASTER_KEY").and_return(nil)
      expect(SignalClient.enabled?).to be false
    end
  end

  describe ".trigger_alert" do
    before do
      stub_request(:post, "#{signal_url}/api/v1/alerts")
        .to_return(status: 200, body: "", headers: {})
    end

    it "posts to Signal alerts endpoint" do
      SignalClient.trigger_alert(source: "beacon", title: "API Down", severity: "critical")
      expect(WebMock).to have_requested(:post, "#{signal_url}/api/v1/alerts")
    end

    it "returns true on success" do
      result = SignalClient.trigger_alert(source: "beacon", title: "Test", severity: "minor")
      expect(result).to be true
    end

    it "returns false on HTTP error" do
      stub_request(:post, "#{signal_url}/api/v1/alerts").to_return(status: 500)
      result = SignalClient.trigger_alert(source: "beacon", title: "Test", severity: "minor")
      expect(result).to be false
    end

    it "returns false and does not raise on network error" do
      stub_request(:post, "#{signal_url}/api/v1/alerts").to_raise(Faraday::ConnectionFailed.new("refused"))
      result = SignalClient.trigger_alert(source: "beacon", title: "Test", severity: "minor")
      expect(result).to be false
    end

    it "returns false without calling API when disabled" do
      allow(ENV).to receive(:[]).with("SIGNAL_MASTER_KEY").and_return(nil)
      result = SignalClient.trigger_alert(source: "beacon", title: "Test", severity: "minor")
      expect(result).to be false
      expect(WebMock).not_to have_requested(:post, anything)
    end
  end

  describe ".resolve_alert" do
    before do
      stub_request(:post, "#{signal_url}/api/v1/alerts/resolve")
        .to_return(status: 200, body: "", headers: {})
    end

    it "posts to Signal resolve endpoint" do
      SignalClient.resolve_alert(source: "beacon", title: "API Down")
      expect(WebMock).to have_requested(:post, "#{signal_url}/api/v1/alerts/resolve")
    end
  end

  describe ".create_incident" do
    let(:monitor) { build(:uptime_monitor, name: "My API", url: "https://api.example.com") }

    before do
      stub_request(:post, "#{signal_url}/api/v1/alerts").to_return(status: 200, body: "")
    end

    it "calls trigger_alert with beacon source" do
      SignalClient.create_incident(
        title: "API Down",
        severity: "critical",
        monitor: monitor,
        started_at: Time.current
      )
      expect(WebMock).to have_requested(:post, "#{signal_url}/api/v1/alerts")
        .with(body: hash_including("source" => "beacon"))
    end
  end

  describe ".send_sms" do
    before do
      stub_request(:post, "#{signal_url}/api/v1/sms").to_return(status: 200)
    end

    it "posts to the SMS endpoint" do
      SignalClient.send_sms("+15550000001", "Outage detected")
      expect(WebMock).to have_requested(:post, "#{signal_url}/api/v1/sms")
    end
  end
end
