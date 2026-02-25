require "rails_helper"

RSpec.describe StatusPageMonitor, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:status_page) }
    it { is_expected.to belong_to(:uptime_monitor) }
  end

  describe "validations" do
    subject do
      sp  = create(:status_page)
      mon = create(:uptime_monitor)
      create(:status_page_monitor, status_page: sp, uptime_monitor: mon)
      build(:status_page_monitor, status_page: sp, uptime_monitor: mon)
    end

    it "validates uniqueness of status_page_id scoped to monitor_id" do
      expect(subject).not_to be_valid
      expect(subject.errors[:status_page_id]).to be_present
    end
  end

  describe "scopes" do
    let(:page) { create(:status_page) }
    let!(:visible_spm)   { create(:status_page_monitor, status_page: page, visible: true,  position: 2) }
    let!(:invisible_spm) { create(:status_page_monitor, status_page: page, visible: false, position: 1) }

    describe ".visible" do
      it "returns only visible monitors" do
        expect(page.status_page_monitors.visible).to include(visible_spm)
        expect(page.status_page_monitors.visible).not_to include(invisible_spm)
      end
    end

    describe ".ordered" do
      it "orders by position" do
        m3 = create(:status_page_monitor, status_page: page, visible: true, position: 3)
        ordered = page.status_page_monitors.ordered.to_a
        expect(ordered.map(&:position)).to eq(ordered.map(&:position).sort)
      end
    end
  end

  describe "#name" do
    it "returns display_name when set" do
      spm = build(:status_page_monitor, :with_display_name, display_name: "My API")
      expect(spm.name).to eq("My API")
    end

    it "falls back to the uptime_monitor name" do
      monitor = create(:uptime_monitor, name: "Production API")
      spm = build(:status_page_monitor, uptime_monitor: monitor, display_name: nil)
      expect(spm.name).to eq("Production API")
    end
  end

  describe "#status" do
    it "returns the current monitor status" do
      monitor = create(:uptime_monitor, :up)
      spm = build(:status_page_monitor, uptime_monitor: monitor)
      expect(spm.status).to eq("up")
    end
  end
end
