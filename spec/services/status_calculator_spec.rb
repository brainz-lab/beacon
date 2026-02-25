require "rails_helper"

RSpec.describe StatusCalculator, type: :service do
  let(:project) { create(:project) }
  let(:page)    { create(:status_page, project: project) }
  subject(:calculator) { StatusCalculator.new(page) }

  describe "#overall_status" do
    it "returns operational when no monitors" do
      expect(calculator.overall_status).to eq("operational")
    end

    it "delegates to status_page#calculate_status" do
      allow(page).to receive(:calculate_status).and_return("partial_outage")
      expect(calculator.overall_status).to eq("partial_outage")
    end
  end

  describe "#status_info" do
    it "returns the correct label and color for operational" do
      info = calculator.status_info
      expect(info[:label]).to eq("All Systems Operational")
      expect(info[:color]).to eq("#10B981")
    end

    it "returns info for major_outage when status is major_outage" do
      allow(page).to receive(:calculate_status).and_return("major_outage")
      info = calculator.status_info
      expect(info[:label]).to include("Major Outage")
      expect(info[:priority]).to eq(3)
    end
  end

  describe "#component_statuses" do
    it "returns an array of component data" do
      monitor = create(:uptime_monitor, :up, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: monitor)

      statuses = calculator.component_statuses
      expect(statuses.size).to eq(1)
      expect(statuses.first[:status]).to eq("up")
      expect(statuses.first[:name]).to be_present
    end

    it "returns empty array when no monitors on page" do
      expect(calculator.component_statuses).to eq([])
    end
  end

  describe "#uptime_summary" do
    it "returns overall uptime and per-monitor breakdown" do
      monitor = create(:uptime_monitor, :up, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: monitor)

      summary = calculator.uptime_summary(days: 30)
      expect(summary).to have_key(:overall)
      expect(summary).to have_key(:by_monitor)
      expect(summary[:by_monitor].first[:id]).to eq(monitor.id)
    end
  end

  describe "#groups_with_statuses" do
    it "returns groups keyed by group_name with monitors array and status" do
      m1 = create(:uptime_monitor, :up, project: project)
      m2 = create(:uptime_monitor, :up, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m1, group_name: "API", visible: true)
      create(:status_page_monitor, status_page: page, uptime_monitor: m2, group_name: "API", visible: true)

      groups = calculator.groups_with_statuses
      expect(groups).to have_key("API")
      expect(groups["API"][:monitors].size).to eq(2)
      expect(groups["API"][:status]).to eq("operational")
    end

    it "reports partial_outage when some group monitors are down" do
      m_up   = create(:uptime_monitor, :up,   project: project)
      m_down = create(:uptime_monitor, :down, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_up,   group_name: "Web", visible: true)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_down, group_name: "Web", visible: true)

      groups = calculator.groups_with_statuses
      expect(groups["Web"][:status]).to eq("partial_outage")
    end
  end
end
