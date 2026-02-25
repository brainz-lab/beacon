require "rails_helper"

RSpec.describe StatusPage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:status_page_monitors).dependent(:destroy) }
    it { is_expected.to have_many(:uptime_monitors).through(:status_page_monitors) }
    it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:status_page) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it "validates slug format (alphanumeric + dashes only)" do
      page = build(:status_page, slug: "UPPER_case_invalid!")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "accepts a valid slug" do
      page = build(:status_page, slug: "my-status-page-1")
      expect(page).to be_valid
    end
  end

  describe "callbacks" do
    it "generates slug from name if blank" do
      page = create(:status_page, name: "My Services Status")
      expect(page.slug).to eq("my-services-status")
    end

    it "does not overwrite an existing slug" do
      page = build(:status_page, name: "My Page", slug: "custom-slug")
      page.save!
      expect(page.slug).to eq("custom-slug")
    end
  end

  describe "STATUSES constant" do
    it "defines operational, degraded, partial_outage, major_outage" do
      expect(StatusPage::STATUSES.keys).to match_array(%w[operational degraded partial_outage major_outage])
    end

    it "has priority ordering" do
      expect(StatusPage::STATUSES["operational"][:priority]).to eq(0)
      expect(StatusPage::STATUSES["major_outage"][:priority]).to eq(3)
    end
  end

  describe "#calculate_status" do
    let(:project) { create(:project) }
    let(:page)    { create(:status_page, project: project) }

    it "returns operational when no monitors" do
      expect(page.calculate_status).to eq("operational")
    end

    it "returns operational when all monitors are up" do
      m1 = create(:uptime_monitor, :up, project: project)
      m2 = create(:uptime_monitor, :up, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m1)
      create(:status_page_monitor, status_page: page, uptime_monitor: m2)
      expect(page.calculate_status).to eq("operational")
    end

    it "returns major_outage when all monitors are down" do
      m1 = create(:uptime_monitor, :down, project: project)
      m2 = create(:uptime_monitor, :down, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m1)
      create(:status_page_monitor, status_page: page, uptime_monitor: m2)
      expect(page.calculate_status).to eq("major_outage")
    end

    it "returns partial_outage when some monitors are down" do
      m_up   = create(:uptime_monitor, :up,   project: project)
      m_down = create(:uptime_monitor, :down, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_up)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_down)
      expect(page.calculate_status).to eq("partial_outage")
    end

    it "returns degraded when some monitors are degraded" do
      m_up  = create(:uptime_monitor, :up,       project: project)
      m_deg = create(:uptime_monitor, :degraded, project: project)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_up)
      create(:status_page_monitor, status_page: page, uptime_monitor: m_deg)
      expect(page.calculate_status).to eq("degraded")
    end
  end

  describe "#status_info" do
    it "returns the correct status configuration" do
      page = build(:status_page, current_status: "degraded")
      info = page.status_info
      expect(info[:label]).to eq("Degraded Performance")
      expect(info[:color]).to be_present
    end

    it "falls back to operational for unknown status" do
      page = build(:status_page, current_status: "unknown")
      expect(page.status_info).to eq(StatusPage::STATUSES["operational"])
    end
  end

  describe "#confirmed_subscriptions" do
    let(:page) { create(:status_page) }

    it "returns only confirmed subscriptions" do
      confirmed = create(:status_subscription, :confirmed, status_page: page)
      pending   = create(:status_subscription, :pending,   status_page: page)

      expect(page.confirmed_subscriptions).to include(confirmed)
      expect(page.confirmed_subscriptions).not_to include(pending)
    end
  end

  describe "#monitors_by_group" do
    let(:page) { create(:status_page) }

    it "groups visible monitors by group_name" do
      m1 = create(:uptime_monitor)
      m2 = create(:uptime_monitor)
      create(:status_page_monitor, status_page: page, uptime_monitor: m1, group_name: "API")
      create(:status_page_monitor, status_page: page, uptime_monitor: m2, group_name: "API")
      create(:status_page_monitor, status_page: page, uptime_monitor: create(:uptime_monitor),
             group_name: "Web", visible: false)

      groups = page.monitors_by_group
      expect(groups).to have_key("API")
      expect(groups["API"].size).to eq(2)
      expect(groups.keys).not_to include("Web")
    end
  end
end
