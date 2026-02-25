require "rails_helper"

RSpec.describe AlertRule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:uptime_monitor) }
  end

  describe "validations" do
    subject { build(:alert_rule) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:condition_type) }
    it {
      is_expected.to validate_inclusion_of(:condition_type).in_array(
        %w[status_change response_time ssl_expiry consecutive_failures status_code uptime_percentage]
      )
    }
  end

  describe "scopes" do
    let(:monitor) { create(:uptime_monitor) }
    let!(:enabled_rule)  { create(:alert_rule, :status_change, uptime_monitor: monitor, enabled: true) }
    let!(:disabled_rule) { create(:alert_rule, :response_time, uptime_monitor: monitor, enabled: false) }

    describe ".enabled" do
      it "returns only enabled rules" do
        expect(monitor.alert_rules.enabled).to include(enabled_rule)
        expect(monitor.alert_rules.enabled).not_to include(disabled_rule)
      end
    end

    describe ".by_type" do
      it "filters by condition_type" do
        results = monitor.alert_rules.by_type("status_change")
        expect(results).to include(enabled_rule)
        expect(results).not_to include(disabled_rule)
      end
    end
  end

  describe "#condition_description" do
    it "describes status_change conditions" do
      rule = build(:alert_rule, :status_change,
                   condition_config: { "from" => "up", "to" => "down" })
      expect(rule.condition_description).to include("Status changes from up to down")
    end

    it "describes response_time with gt operator" do
      rule = build(:alert_rule, :response_time,
                   condition_config: { "operator" => "gt", "value" => 2000 })
      expect(rule.condition_description).to include("exceeds 2000ms")
    end

    it "describes response_time with lt operator" do
      rule = build(:alert_rule, :response_time,
                   condition_config: { "operator" => "lt", "value" => 100 })
      expect(rule.condition_description).to include("is below 100ms")
    end

    it "describes ssl_expiry conditions" do
      rule = build(:alert_rule, :ssl_expiry,
                   condition_config: { "days_before" => 14 })
      expect(rule.condition_description).to include("14 days")
    end

    it "uses defaults when condition_config is empty" do
      rule = build(:alert_rule, condition_type: "status_change", condition_config: {})
      desc = rule.condition_description
      expect(desc).to include("any")
      expect(desc).to include("down")
    end
  end

  describe "#triggered?" do
    let(:monitor) { create(:uptime_monitor, :up) }

    describe "status_change" do
      it "returns false when no check_result given" do
        rule = build(:alert_rule, :status_change, uptime_monitor: monitor)
        expect(rule.triggered?(nil)).to be false
      end

      it "returns true when monitor status matches expected_to" do
        monitor.update_columns(status: "down")
        rule = build(:alert_rule, :status_change,
                     uptime_monitor: monitor,
                     condition_config: { "to" => "down" })
        check = build(:check_result, :down, uptime_monitor: monitor)
        # monitor.status == expected_to
        expect(rule.triggered?(check)).to be true
      end
    end

    describe "response_time" do
      it "returns false when check_result has no response_time_ms" do
        rule = build(:alert_rule, :response_time, uptime_monitor: monitor)
        check = build(:check_result, response_time_ms: nil)
        expect(rule.triggered?(check)).to be false
      end

      it "returns true when response_time_ms exceeds threshold (gt)" do
        rule = build(:alert_rule, :response_time,
                     uptime_monitor: monitor,
                     condition_config: { "operator" => "gt", "value" => 500 })
        check = build(:check_result, response_time_ms: 800)
        expect(rule.triggered?(check)).to be true
      end

      it "returns false when response_time_ms is below threshold (gt)" do
        rule = build(:alert_rule, :response_time,
                     uptime_monitor: monitor,
                     condition_config: { "operator" => "gt", "value" => 500 })
        check = build(:check_result, response_time_ms: 200)
        expect(rule.triggered?(check)).to be false
      end
    end

    describe "ssl_expiry" do
      it "returns false when ssl_expiry_at is not set" do
        rule = build(:alert_rule, :ssl_expiry, uptime_monitor: monitor)
        expect(rule.triggered?).to be false
      end

      it "returns true when SSL expiry is within the threshold days" do
        monitor.update_columns(ssl_expiry_at: 10.days.from_now)
        rule = build(:alert_rule, :ssl_expiry,
                     uptime_monitor: monitor,
                     condition_config: { "days_before" => 30 })
        expect(rule.triggered?).to be true
      end

      it "returns false when SSL expiry is beyond the threshold" do
        monitor.update_columns(ssl_expiry_at: 60.days.from_now)
        rule = build(:alert_rule, :ssl_expiry,
                     uptime_monitor: monitor,
                     condition_config: { "days_before" => 30 })
        expect(rule.triggered?).to be false
      end
    end
  end
end
