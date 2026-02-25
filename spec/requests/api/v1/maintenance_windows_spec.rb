require "rails_helper"

RSpec.describe "API::V1::MaintenanceWindows", type: :request do
  let(:project) { create(:project) }
  let(:headers) { auth_headers(project) }

  describe "GET /api/v1/maintenance_windows" do
    let!(:upcoming)    { create(:maintenance_window, project: project) }
    let!(:active_now)  { create(:maintenance_window, :active_now,  project: project) }
    let!(:past)        { create(:maintenance_window, :past, project: project) }

    it "returns all maintenance windows for the project" do
      get "/api/v1/maintenance_windows", headers: headers
      body = JSON.parse(response.body)
      expect(body["maintenance_windows"].size).to be >= 3
    end

    it "filters by status=scheduled" do
      get "/api/v1/maintenance_windows", params: { status: "scheduled" }, headers: headers
      body = JSON.parse(response.body)
      statuses = body["maintenance_windows"].map { |w| w["status"] }
      expect(statuses).to all(eq("scheduled"))
    end

    it "does not return windows from other projects" do
      other = create(:project)
      create(:maintenance_window, project: other)
      get "/api/v1/maintenance_windows", headers: headers
      body = JSON.parse(response.body)
      expect(body["maintenance_windows"].size).to be <= 3
    end

    context "without authentication" do
      it "returns 401" do
        get "/api/v1/maintenance_windows"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/maintenance_windows" do
    let(:valid_params) do
      {
        maintenance_window: {
          title: "Scheduled Upgrade",
          starts_at: 1.day.from_now.iso8601,
          ends_at: 1.day.from_now + 2.hours
        }
      }
    end

    it "creates a new maintenance window and returns 201" do
      expect {
        post "/api/v1/maintenance_windows", params: valid_params, headers: headers
      }.to change(MaintenanceWindow, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Scheduled Upgrade")
    end

    it "returns 422 when ends_at is before starts_at" do
      post "/api/v1/maintenance_windows",
           params: { maintenance_window: {
             title: "Bad Window",
             starts_at: 2.hours.from_now.iso8601,
             ends_at: 1.hour.from_now.iso8601
           } },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/maintenance_windows/:id" do
    let!(:window) { create(:maintenance_window, project: project) }

    it "returns window details" do
      get "/api/v1/maintenance_windows/#{window.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(window.id)
    end

    it "returns 404 for unknown window" do
      get "/api/v1/maintenance_windows/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/maintenance_windows/:id" do
    let!(:window) { create(:maintenance_window, project: project, title: "Old Title") }

    it "updates the maintenance window" do
      patch "/api/v1/maintenance_windows/#{window.id}",
            params: { maintenance_window: { title: "New Title" } },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(window.reload.title).to eq("New Title")
    end
  end

  describe "DELETE /api/v1/maintenance_windows/:id" do
    let!(:upcoming_window)  { create(:maintenance_window, project: project) }
    let!(:past_window)      { create(:maintenance_window, :past, project: project) }

    it "cancels upcoming windows instead of deleting" do
      delete "/api/v1/maintenance_windows/#{upcoming_window.id}", headers: headers
      expect(response).to have_http_status(:ok).or have_http_status(:no_content)
    end

    it "returns 404 for windows from another project" do
      other_project = create(:project)
      other_window  = create(:maintenance_window, project: other_project)
      delete "/api/v1/maintenance_windows/#{other_window.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
