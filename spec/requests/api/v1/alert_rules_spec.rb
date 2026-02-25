require "rails_helper"

RSpec.describe "API::V1::AlertRules", type: :request do
  let(:project) { create(:project) }
  let(:monitor) { create(:uptime_monitor, project: project) }
  let(:headers) { auth_headers(project) }

  describe "GET /api/v1/monitors/:monitor_id/alert_rules" do
    let!(:rule1) { create(:alert_rule, :status_change, uptime_monitor: monitor) }
    let!(:rule2) { create(:alert_rule, :response_time, uptime_monitor: monitor) }

    it "returns all alert rules for the monitor" do
      get "/api/v1/monitors/#{monitor.id}/alert_rules", headers: headers
      body = JSON.parse(response.body)
      expect(body["alert_rules"].size).to eq(2)
    end

    it "returns 404 when monitor belongs to another project" do
      other_project = create(:project)
      other_monitor = create(:uptime_monitor, project: other_project)
      get "/api/v1/monitors/#{other_monitor.id}/alert_rules", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/monitors/:monitor_id/alert_rules" do
    let(:rule_params) do
      { alert_rule: { name: "High Response Time", condition_type: "response_time",
                      threshold: 1000, comparison: "gt", enabled: true } }
    end

    it "creates a new alert rule and returns 201" do
      expect {
        post "/api/v1/monitors/#{monitor.id}/alert_rules", params: rule_params, headers: headers
      }.to change(AlertRule, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("High Response Time")
    end

    it "returns 422 for invalid params" do
      post "/api/v1/monitors/#{monitor.id}/alert_rules",
           params: { alert_rule: { name: "", condition_type: "invalid_type" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/monitors/:monitor_id/alert_rules/:id" do
    let!(:rule) { create(:alert_rule, :status_change, uptime_monitor: monitor) }

    it "returns rule details" do
      get "/api/v1/monitors/#{monitor.id}/alert_rules/#{rule.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(rule.id)
      expect(body).to have_key("notify_channels") # detailed view
    end
  end

  describe "PATCH /api/v1/monitors/:monitor_id/alert_rules/:id" do
    let!(:rule) { create(:alert_rule, uptime_monitor: monitor, enabled: true) }

    it "updates the alert rule" do
      patch "/api/v1/monitors/#{monitor.id}/alert_rules/#{rule.id}",
            params: { alert_rule: { enabled: false } },
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(rule.reload.enabled).to be false
    end
  end

  describe "DELETE /api/v1/monitors/:monitor_id/alert_rules/:id" do
    let!(:rule) { create(:alert_rule, uptime_monitor: monitor) }

    it "deletes the alert rule and returns 204" do
      expect {
        delete "/api/v1/monitors/#{monitor.id}/alert_rules/#{rule.id}", headers: headers
      }.to change(AlertRule, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
