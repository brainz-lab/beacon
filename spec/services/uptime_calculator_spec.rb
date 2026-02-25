require "rails_helper"

RSpec.describe UptimeCalculator, type: :service, timescaledb: true do
  let(:monitor) { create(:uptime_monitor) }

  def create_check(status:, checked_at:, response_time_ms: 120)
    create(:check_result,
           uptime_monitor: monitor,
           status: status,
           checked_at: checked_at,
           response_time_ms: response_time_ms)
  end

  before do
    # 8 successful, 2 failed in the last 30 days
    8.times { |i| create_check(status: "up",   checked_at: (i + 1).hours.ago) }
    2.times { |i| create_check(status: "down", checked_at: (i + 10).hours.ago) }
  end

  subject(:calculator) { UptimeCalculator.new(monitor, period: 30.days) }

  describe "#calculate" do
    it "returns 80.0 with 8 up and 2 down checks" do
      expect(calculator.calculate).to eq(80.0)
    end

    it "returns 100.0 when all checks are successful" do
      monitor2 = create(:uptime_monitor)
      3.times { create_check(status: "up", checked_at: 1.hour.ago).tap { |c| c.update_column(:monitor_id, monitor2.id) } }
      calc = UptimeCalculator.new(monitor2, period: 30.days)
      expect(calc.calculate).to eq(100.0)
    end

    it "returns 100.0 when no checks exist (no data = assume ok)" do
      empty_monitor = create(:uptime_monitor)
      calc = UptimeCalculator.new(empty_monitor, period: 30.days)
      expect(calc.calculate).to eq(100.0)
    end
  end

  describe "#total_checks" do
    it "counts all checks within the period" do
      expect(calculator.total_checks).to eq(10)
    end
  end

  describe "#successful_checks" do
    it "counts only successful checks" do
      expect(calculator.successful_checks).to eq(8)
    end
  end

  describe "#failed_checks" do
    it "counts only failed checks" do
      expect(calculator.failed_checks).to eq(2)
    end
  end

  describe "#average_response_time" do
    it "returns 0 when no checks exist" do
      empty = create(:uptime_monitor)
      calc = UptimeCalculator.new(empty, period: 30.days)
      expect(calc.average_response_time).to eq(0)
    end
  end

  describe "#percentile_response_time" do
    it "returns 0 when no checks exist" do
      empty = create(:uptime_monitor)
      calc = UptimeCalculator.new(empty, period: 30.days)
      expect(calc.percentile_response_time(30.days, 95)).to eq(0)
    end
  end

  describe "#downtime_minutes" do
    it "returns a positive number when downtime exists" do
      expect(calculator.downtime_minutes).to be > 0
    end
  end
end
