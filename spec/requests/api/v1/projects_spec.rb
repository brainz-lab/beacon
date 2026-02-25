require "rails_helper"

RSpec.describe "API::V1::Projects", type: :request do
  let(:master_key)  { "test_master_key_beacon" }
  let(:master_hdrs) { { "X-Master-Key" => master_key } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BEACON_MASTER_KEY").and_return(master_key)
  end

  describe "POST /api/v1/projects/provision" do
    context "with platform_project_id" do
      let(:uuid)   { SecureRandom.uuid }
      let(:params) { { platform_project_id: uuid, name: "My App" } }

      it "creates a new project and returns 201" do
        expect {
          post "/api/v1/projects/provision", params: params, headers: master_hdrs
        }.to change(Project, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["api_key"]).to start_with("bl_beacon_")
        expect(body["ingest_key"]).to start_with("bl_beacon_ingest_")
        expect(body["platform_project_id"]).to eq(uuid)
      end

      it "is idempotent — returns 200 and existing project on repeat call" do
        post "/api/v1/projects/provision", params: params, headers: master_hdrs
        expect {
          post "/api/v1/projects/provision", params: params, headers: master_hdrs
        }.not_to change(Project, :count)

        expect(response).to have_http_status(:ok)
      end

      it "updates the project name on repeat call" do
        post "/api/v1/projects/provision", params: params, headers: master_hdrs
        post "/api/v1/projects/provision",
             params: { platform_project_id: uuid, name: "Updated Name" },
             headers: master_hdrs

        project = Project.find_by(platform_project_id: uuid)
        expect(project.name).to eq("Updated Name")
      end
    end

    context "in standalone mode (name only)" do
      it "creates a project by name and returns 201" do
        expect {
          post "/api/v1/projects/provision", params: { name: "Standalone App" }, headers: master_hdrs
        }.to change(Project, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "assigns a platform_project_id automatically" do
        post "/api/v1/projects/provision", params: { name: "Standalone" }, headers: master_hdrs
        project = Project.find_by(name: "Standalone")
        expect(project.platform_project_id).to be_present
      end
    end

    context "with neither platform_project_id nor name" do
      it "returns 400 Bad Request" do
        post "/api/v1/projects/provision", params: {}, headers: master_hdrs
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without master key" do
      it "returns 401 Unauthorized" do
        post "/api/v1/projects/provision", params: { name: "App" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 for a wrong master key" do
        post "/api/v1/projects/provision",
             params: { name: "App" },
             headers: { "X-Master-Key" => "wrong_key" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/projects/lookup" do
    let!(:project) { create(:project, name: "Lookup App") }

    it "finds by name and returns the project" do
      get "/api/v1/projects/lookup", params: { name: "Lookup App" }, headers: master_hdrs
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Lookup App")
      expect(body["api_key"]).to eq(project.api_key)
    end

    it "finds by platform_project_id" do
      platform_project = create(:project, :with_platform)
      get "/api/v1/projects/lookup",
          params: { platform_project_id: platform_project.platform_project_id },
          headers: master_hdrs
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["platform_project_id"]).to eq(platform_project.platform_project_id)
    end

    it "returns 404 when project not found" do
      get "/api/v1/projects/lookup", params: { name: "nonexistent" }, headers: master_hdrs
      expect(response).to have_http_status(:not_found)
    end
  end
end
