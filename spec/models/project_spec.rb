require "rails_helper"

RSpec.describe Project, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:uptime_monitors).dependent(:destroy) }
    it { is_expected.to have_many(:status_pages).dependent(:destroy) }
    it { is_expected.to have_many(:maintenance_windows).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:api_key) }
    it { is_expected.to validate_uniqueness_of(:api_key) }
    it { is_expected.to validate_uniqueness_of(:platform_project_id).allow_blank }
  end

  describe "callbacks" do
    describe "#generate_keys" do
      it "generates api_key with bl_beacon_ prefix" do
        project = create(:project)
        expect(project.api_key).to start_with("bl_beacon_")
      end

      it "generates ingest_key with bl_beacon_ingest_ prefix" do
        project = create(:project)
        expect(project.ingest_key).to start_with("bl_beacon_ingest_")
      end

      it "does not overwrite existing api_key" do
        project = build(:project)
        project.api_key = "bl_beacon_custom_key"
        project.save!
        expect(project.api_key).to eq("bl_beacon_custom_key")
      end
    end
  end

  describe ".find_by_api_key" do
    let!(:project) { create(:project) }

    it "finds by api_key" do
      found = Project.find_by_api_key(project.api_key)
      expect(found).to eq(project)
    end

    it "finds by ingest_key" do
      found = Project.find_by_api_key(project.ingest_key)
      expect(found).to eq(project)
    end

    it "returns nil for unknown key" do
      expect(Project.find_by_api_key("bl_beacon_unknown")).to be_nil
    end
  end

  describe ".find_or_create_from_platform" do
    it "creates a project if none exists" do
      uuid = SecureRandom.uuid
      expect {
        Project.find_or_create_from_platform(platform_project_id: uuid, name: "New App")
      }.to change(Project, :count).by(1)
    end

    it "returns existing project if already present" do
      uuid = SecureRandom.uuid
      existing = create(:project, platform_project_id: uuid, name: "Existing")
      result = Project.find_or_create_from_platform(platform_project_id: uuid, name: "Other")
      expect(result).to eq(existing)
    end
  end

  describe "#monitors_summary" do
    let(:project) { create(:project) }

    it "returns counts by status" do
      create(:uptime_monitor, :up,   project: project)
      create(:uptime_monitor, :down, project: project)
      create(:uptime_monitor, :degraded, project: project)
      create(:uptime_monitor, :paused,   project: project)

      summary = project.monitors_summary
      expect(summary[:total]).to eq(4)
      expect(summary[:up]).to eq(1)
      expect(summary[:down]).to eq(1)
      expect(summary[:degraded]).to eq(1)
      expect(summary[:paused]).to eq(1)
    end

    it "returns zeros when no monitors exist" do
      summary = project.monitors_summary
      expect(summary[:total]).to eq(0)
    end
  end
end
