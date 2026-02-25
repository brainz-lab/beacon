require "rails_helper"

RSpec.describe IncidentUpdate, type: :model do
  before { allow(IncidentNotificationJob).to receive(:perform_later) }

  describe "associations" do
    it { is_expected.to belong_to(:incident) }
  end

  describe "validations" do
    subject { build(:incident_update) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:message) }
  end

  describe "scopes" do
    let(:incident) { create(:incident, uptime_monitor: create(:uptime_monitor)) }
    let!(:update1) { create(:incident_update, incident: incident, created_at: 2.hours.ago) }
    let!(:update2) { create(:incident_update, incident: incident, created_at: 1.hour.ago) }

    describe ".recent" do
      it "orders by created_at descending" do
        ordered = incident.updates.recent.to_a
        expect(ordered.first).to eq(update2)
        expect(ordered.last).to eq(update1)
      end
    end

    describe ".chronological" do
      it "orders by created_at ascending" do
        ordered = incident.updates.chronological.to_a
        expect(ordered.first).to eq(update1)
        expect(ordered.last).to eq(update2)
      end
    end
  end

  describe "#human_created?" do
    it "returns false for system-created updates" do
      update = build(:incident_update, created_by: "system")
      expect(update.human_created?).to be false
    end

    it "returns true for user-created updates" do
      update = build(:incident_update, :human)
      expect(update.human_created?).to be true
    end

    it "returns false when created_by is blank" do
      update = build(:incident_update, created_by: nil)
      expect(update.human_created?).to be false
    end
  end
end
