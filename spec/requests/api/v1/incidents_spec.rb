require "rails_helper"

RSpec.describe "API::V1::Incidents", type: :request do
  let(:project) { create(:project) }
  let(:headers) { auth_headers(project) }
  let(:monitor) { create(:uptime_monitor, project: project) }

  before { allow(IncidentNotificationJob).to receive(:perform_later) }

  describe "GET /api/v1/incidents" do
    let!(:active_incident)   { create(:incident, :investigating, uptime_monitor: monitor) }
    let!(:resolved_incident) { create(:incident, :resolved,      uptime_monitor: monitor) }

    it "returns all incidents for the project" do
      get "/api/v1/incidents", headers: headers
      body = JSON.parse(response.body)
      expect(body["incidents"].size).to eq(2)
    end

    it "includes summary with active count" do
      get "/api/v1/incidents", headers: headers
      summary = JSON.parse(response.body)["summary"]
      expect(summary["active"]).to eq(1)
    end

    it "filters active incidents" do
      get "/api/v1/incidents", params: { status: "active" }, headers: headers
      body = JSON.parse(response.body)
      ids = body["incidents"].map { |i| i["id"] }
      expect(ids).to include(active_incident.id)
      expect(ids).not_to include(resolved_incident.id)
    end

    it "filters resolved incidents" do
      get "/api/v1/incidents", params: { status: "resolved" }, headers: headers
      body = JSON.parse(response.body)
      ids = body["incidents"].map { |i| i["id"] }
      expect(ids).to include(resolved_incident.id)
      expect(ids).not_to include(active_incident.id)
    end

    it "filters by severity" do
      critical_incident = create(:incident, :critical, uptime_monitor: monitor)
      get "/api/v1/incidents", params: { severity: "critical" }, headers: headers
      body = JSON.parse(response.body)
      ids = body["incidents"].map { |i| i["id"] }
      expect(ids).to include(critical_incident.id)
      expect(ids).not_to include(active_incident.id)
    end

    it "filters by monitor_id" do
      other_monitor   = create(:uptime_monitor, project: project)
      other_incident  = create(:incident, uptime_monitor: other_monitor)
      get "/api/v1/incidents", params: { monitor_id: monitor.id }, headers: headers
      body = JSON.parse(response.body)
      ids = body["incidents"].map { |i| i["id"] }
      expect(ids).to include(active_incident.id)
      expect(ids).not_to include(other_incident.id)
    end

    it "does not return incidents from other projects" do
      other_project  = create(:project)
      other_monitor  = create(:uptime_monitor, project: other_project)
      other_incident = create(:incident, uptime_monitor: other_monitor)

      get "/api/v1/incidents", headers: headers
      body = JSON.parse(response.body)
      ids = body["incidents"].map { |i| i["id"] }
      expect(ids).not_to include(other_incident.id)
    end

    context "without authentication" do
      it "returns 401" do
        get "/api/v1/incidents"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/incidents/:id" do
    let!(:incident) { create(:incident, :investigating, uptime_monitor: monitor) }

    it "returns full incident detail" do
      get "/api/v1/incidents/#{incident.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(incident.id)
      expect(body).to have_key("updates") # detailed view
      expect(body).to have_key("affected_regions")
    end

    it "returns 404 for unknown incident" do
      get "/api/v1/incidents/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for incident from another project" do
      other_project  = create(:project)
      other_monitor  = create(:uptime_monitor, project: other_project)
      other_incident = create(:incident, uptime_monitor: other_monitor)

      get "/api/v1/incidents/#{other_incident.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/incidents/:id" do
    let!(:incident) { create(:incident, :investigating, uptime_monitor: monitor) }

    it "resolves the incident when resolve: true is sent" do
      patch "/api/v1/incidents/#{incident.id}",
            params: { resolve: true, resolution_notes: "Fixed" },
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(incident.reload.status).to eq("resolved")
    end

    it "adds a status update when status and message are provided" do
      expect {
        patch "/api/v1/incidents/#{incident.id}",
              params: { status: "identified", message: "Root cause found" },
              headers: headers
      }.to change { incident.updates.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(incident.reload.status).to eq("identified")
    end

    it "updates incident fields directly" do
      patch "/api/v1/incidents/#{incident.id}",
            params: { incident: { severity: "critical" } },
            headers: headers
      expect(incident.reload.severity).to eq("critical")
    end
  end
end
