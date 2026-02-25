require "rails_helper"

RSpec.describe "API::V1::Monitors", type: :request, timescaledb: true do
  let(:project) { create(:project) }
  let(:headers) { auth_headers(project) }

  describe "GET /api/v1/monitors" do
    let!(:up_monitor)      { create(:uptime_monitor, :up,      project: project) }
    let!(:down_monitor)    { create(:uptime_monitor, :down,    project: project) }
    let!(:paused_monitor)  { create(:uptime_monitor, :paused,  project: project) }

    it "returns all monitors for the project" do
      get "/api/v1/monitors", headers: headers
      body = JSON.parse(response.body)
      expect(body["monitors"].size).to eq(3)
    end

    it "includes a summary" do
      get "/api/v1/monitors", headers: headers
      summary = JSON.parse(response.body)["summary"]
      expect(summary["total"]).to eq(3)
      expect(summary["up"]).to eq(1)
      expect(summary["down"]).to eq(1)
    end

    it "filters by status" do
      get "/api/v1/monitors", params: { status: "down" }, headers: headers
      body = JSON.parse(response.body)
      expect(body["monitors"].size).to eq(1)
      expect(body["monitors"].first["status"]).to eq("down")
    end

    it "filters by monitor_type" do
      tcp_monitor = create(:uptime_monitor, :tcp, project: project)
      get "/api/v1/monitors", params: { type: "tcp" }, headers: headers
      body = JSON.parse(response.body)
      ids = body["monitors"].map { |m| m["id"] }
      expect(ids).to include(tcp_monitor.id)
    end

    it "does not return monitors from other projects" do
      other_project = create(:project)
      create(:uptime_monitor, project: other_project)

      get "/api/v1/monitors", headers: headers
      body = JSON.parse(response.body)
      expect(body["monitors"].size).to eq(3)
    end

    context "without authentication" do
      it "returns 401" do
        get "/api/v1/monitors"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "accepts X-API-Key header" do
      get "/api/v1/monitors", headers: api_key_headers(project)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/monitors" do
    let(:valid_params) do
      { monitor: { name: "New Monitor", monitor_type: "http",
                   url: "https://api.example.com", interval_seconds: 60 } }
    end

    it "creates a new monitor and returns 201" do
      allow(ExecuteCheckJob).to receive(:perform_later)
      expect {
        post "/api/v1/monitors", params: valid_params, headers: headers
      }.to change(UptimeMonitor, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("New Monitor")
    end

    it "schedules an ExecuteCheckJob" do
      allow(ExecuteCheckJob).to receive(:perform_later)
      post "/api/v1/monitors", params: valid_params, headers: headers
      expect(ExecuteCheckJob).to have_received(:perform_later)
    end

    it "returns 422 for invalid params" do
      post "/api/v1/monitors",
           params: { monitor: { name: "", monitor_type: "http", url: "https://example.com" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/monitors/:id" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project) }

    it "returns monitor details" do
      get "/api/v1/monitors/#{monitor.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(monitor.id)
      expect(body).to have_key("interval_seconds") # detailed view
    end

    it "returns 404 for unknown monitor" do
      get "/api/v1/monitors/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when monitor belongs to another project" do
      other_project = create(:project)
      other_monitor = create(:uptime_monitor, project: other_project)
      get "/api/v1/monitors/#{other_monitor.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/monitors/:id" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project, name: "Old Name") }

    it "updates the monitor" do
      patch "/api/v1/monitors/#{monitor.id}",
            params: { monitor: { name: "New Name" } },
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(monitor.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /api/v1/monitors/:id" do
    let!(:monitor) { create(:uptime_monitor, project: project) }

    it "deletes the monitor and returns 204" do
      expect {
        delete "/api/v1/monitors/#{monitor.id}", headers: headers
      }.to change(UptimeMonitor, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/monitors/:id/pause" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project, paused: false) }

    it "pauses the monitor" do
      post "/api/v1/monitors/#{monitor.id}/pause", headers: headers
      expect(response).to have_http_status(:ok)
      expect(monitor.reload.paused).to be true
      expect(JSON.parse(response.body)["paused"]).to be true
    end
  end

  describe "POST /api/v1/monitors/:id/resume" do
    let!(:monitor) { create(:uptime_monitor, :http, :paused, project: project) }

    it "resumes the monitor" do
      allow(ExecuteCheckJob).to receive(:perform_later)
      post "/api/v1/monitors/#{monitor.id}/resume", headers: headers
      expect(response).to have_http_status(:ok)
      expect(monitor.reload.paused).to be false
      expect(ExecuteCheckJob).to have_received(:perform_later)
    end
  end

  describe "POST /api/v1/monitors/:id/check_now" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project) }

    it "executes an immediate check and returns the result" do
      mock_result = instance_double(CheckResult,
                                    success?: true,
                                    status: "up",
                                    response_time_ms: 120,
                                    checked_at: Time.current)
      allow(monitor).to receive(:check!).and_return(mock_result)
      allow_any_instance_of(UptimeMonitor).to receive(:check!).and_return(mock_result)

      post "/api/v1/monitors/#{monitor.id}/check_now", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["status"]).to eq("up")
    end
  end

  describe "GET /api/v1/monitors/:id/uptime" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project) }

    it "returns uptime percentage and bars" do
      calculator = instance_double(UptimeCalculator,
                                   calculate: 99.5,
                                   downtime_humanized: "21m",
                                   uptime_bars: [])
      allow(UptimeCalculator).to receive(:new).and_return(calculator)

      get "/api/v1/monitors/#{monitor.id}/uptime", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["uptime_percentage"]).to eq(99.5)
      expect(body).to have_key("downtime")
      expect(body).to have_key("uptime_bars")
    end
  end

  describe "GET /api/v1/monitors/:id/response_times" do
    let!(:monitor) { create(:uptime_monitor, :http, project: project) }

    it "returns average and series data" do
      get "/api/v1/monitors/#{monitor.id}/response_times", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to have_key("average")
      expect(body).to have_key("series")
    end
  end
end
