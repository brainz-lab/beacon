class SignalClient
  class << self
    # Trigger an alert to Signal
    def trigger_alert(source:, title:, severity:, data: {})
      return false unless enabled?

      response = connection.post("/api/v1/alerts") do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-API-Key"] = api_key
        req.body = {
          source: source,
          title: title,
          severity: severity,
          data: data,
          triggered_at: Time.current.iso8601
        }.to_json
      end

      unless response.success?
        Rails.logger.error "[SignalClient] Alert failed: #{response.status} - #{response.body}"
      end

      response.success?
    rescue Faraday::Error => e
      Rails.logger.error "[SignalClient] Connection error: #{e.message}"
      false
    end

    # Send SMS via Signal's SMS gateway
    def send_sms(phone_number, message)
      return false unless enabled?

      response = connection.post("/api/v1/sms") do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-API-Key"] = api_key
        req.body = {
          to: phone_number,
          message: message
        }.to_json
      end

      response.success?
    rescue Faraday::Error => e
      Rails.logger.error "[SignalClient] SMS error: #{e.message}"
      false
    end

    # Resolve an alert in Signal
    def resolve_alert(source:, title:, data: {})
      return false unless enabled?

      response = connection.post("/api/v1/alerts/resolve") do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-API-Key"] = api_key
        req.body = {
          source: source,
          title: title,
          data: data,
          resolved_at: Time.current.iso8601
        }.to_json
      end

      response.success?
    rescue Faraday::Error => e
      Rails.logger.error "[SignalClient] Resolution error: #{e.message}"
      false
    end

    # Create an incident in Signal
    def create_incident(title:, severity:, monitor:, started_at:)
      trigger_alert(
        source: "beacon",
        title: "[Beacon] #{title}",
        severity: severity,
        data: {
          type: "incident_created",
          monitor_id: monitor.id,
          monitor_name: monitor.name,
          monitor_url: monitor.url || "#{monitor.host}:#{monitor.port}",
          started_at: started_at.iso8601
        }
      )
    end

    # Report incident resolved to Signal
    def resolve_incident(incident)
      resolve_alert(
        source: "beacon",
        title: "[Beacon] #{incident.title}",
        data: {
          type: "incident_resolved",
          incident_id: incident.id,
          monitor_id: incident.monitor_id,
          monitor_name: incident.monitor.name,
          duration: incident.duration_humanized,
          resolved_at: incident.resolved_at.iso8601
        }
      )
    end

    # Report SSL expiry warning
    def ssl_expiry_warning(monitor:, days_until_expiry:, expires_at:)
      severity = days_until_expiry <= 7 ? "critical" : (days_until_expiry <= 14 ? "high" : "medium")

      trigger_alert(
        source: "beacon",
        title: "[Beacon] SSL Certificate Expiring Soon",
        severity: severity,
        data: {
          type: "ssl_expiry_warning",
          monitor_id: monitor.id,
          monitor_name: monitor.name,
          domain: monitor.host || URI.parse(monitor.url).host,
          days_until_expiry: days_until_expiry,
          expires_at: expires_at.iso8601
        }
      )
    end

    def enabled?
      signal_url.present? && api_key.present?
    end

    private

    def connection
      @connection ||= Faraday.new(url: signal_url) do |f|
        f.options.timeout = 10
        f.options.open_timeout = 5
        f.adapter Faraday.default_adapter
      end
    end

    def signal_url
      ENV.fetch("SIGNAL_URL", "http://signal:4005")
    end

    def api_key
      ENV["SIGNAL_MASTER_KEY"]
    end
  end
end
