require "rails_helper"

RSpec.describe MaintenanceWindow, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "validations" do
    subject { build(:maintenance_window) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }

    it "validates ends_at is after starts_at" do
      window = build(:maintenance_window, starts_at: 1.hour.from_now, ends_at: 30.minutes.from_now)
      expect(window).not_to be_valid
      expect(window.errors[:ends_at]).to include("must be after start time")
    end

    it "accepts ends_at after starts_at" do
      window = build(:maintenance_window, starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
      expect(window).to be_valid
    end
  end

  describe "scopes" do
    let(:project) { create(:project) }
    let!(:upcoming)    { create(:maintenance_window, project: project, starts_at: 2.hours.from_now, ends_at: 4.hours.from_now) }
    let!(:active)      { create(:maintenance_window, :active_now, project: project) }
    let!(:past)        { create(:maintenance_window, :past, project: project) }
    let!(:scheduled)   { create(:maintenance_window, project: project, status: "scheduled", starts_at: 3.hours.from_now, ends_at: 5.hours.from_now) }
    let!(:in_progress) { create(:maintenance_window, :in_progress, project: project) }

    describe ".upcoming" do
      it "returns windows that start in the future" do
        expect(MaintenanceWindow.upcoming).to include(upcoming, scheduled)
        expect(MaintenanceWindow.upcoming).not_to include(past)
      end
    end

    describe ".active" do
      it "returns currently active windows" do
        expect(MaintenanceWindow.active).to include(active, in_progress)
        expect(MaintenanceWindow.active).not_to include(upcoming, past)
      end
    end

    describe ".past" do
      it "returns completed windows" do
        expect(MaintenanceWindow.past).to include(past)
        expect(MaintenanceWindow.past).not_to include(upcoming)
      end
    end

    describe ".scheduled / .in_progress" do
      it "filters by status column" do
        expect(MaintenanceWindow.scheduled).to include(scheduled)
        expect(MaintenanceWindow.in_progress).to include(in_progress)
      end
    end
  end

  describe "#affected_monitors" do
    let(:project)  { create(:project) }
    let(:monitor1) { create(:uptime_monitor, project: project) }
    let(:monitor2) { create(:uptime_monitor, project: project) }

    it "returns all project monitors when affects_all_monitors is true" do
      window = create(:maintenance_window, :all_monitors, project: project)
      expect(window.affected_monitors).to include(monitor1, monitor2)
    end

    it "returns only specified monitors when affects_all_monitors is false" do
      window = create(:maintenance_window,
                      project: project,
                      affects_all_monitors: false,
                      monitor_ids: [ monitor1.id ])
      expect(window.affected_monitors).to include(monitor1)
      expect(window.affected_monitors).not_to include(monitor2)
    end
  end

  describe "#active?" do
    it "returns true when currently in maintenance window" do
      window = build(:maintenance_window, :active_now)
      expect(window.active?).to be true
    end

    it "returns false when window hasn't started" do
      window = build(:maintenance_window)
      expect(window.active?).to be false
    end
  end

  describe "#upcoming?" do
    it "returns true when starts_at is in the future" do
      window = build(:maintenance_window, starts_at: 1.hour.from_now, ends_at: 3.hours.from_now)
      expect(window.upcoming?).to be true
    end

    it "returns false when starts_at is in the past" do
      window = build(:maintenance_window, :active_now)
      expect(window.upcoming?).to be false
    end
  end

  describe "#duration and #duration_humanized" do
    let(:window) do
      build(:maintenance_window,
            starts_at: Time.current,
            ends_at: 2.hours.from_now + 30.minutes)
    end

    it "calculates duration in seconds" do
      expect(window.duration).to be_within(5).of(9000) # 2.5 hours
    end

    it "formats duration as human-readable string" do
      expect(window.duration_humanized).to eq("2h 30m")
    end

    it "formats short duration as minutes only" do
      short = build(:maintenance_window, starts_at: Time.current, ends_at: 45.minutes.from_now)
      expect(short.duration_humanized).to eq("45m")
    end
  end

  describe "state transitions" do
    let(:window) { create(:maintenance_window) }

    it "start! sets status to in_progress" do
      window.start!
      expect(window.reload.status).to eq("in_progress")
    end

    it "complete! sets status to completed" do
      window.complete!
      expect(window.reload.status).to eq("completed")
    end

    it "cancel! sets status to cancelled" do
      window.cancel!
      expect(window.reload.status).to eq("cancelled")
    end
  end
end
