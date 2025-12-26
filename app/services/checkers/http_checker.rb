require "faraday"
require "faraday/follow_redirects"

module Checkers
  class HTTPChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Build connection
      conn = build_connection

      # Make request
      response = make_request(conn)

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i

      # Check success criteria
      success = check_success(response)

      {
        success: success,
        response_time_ms: response_time_ms,
        status_code: response.status,
        response_size_bytes: response.body&.bytesize || 0,
        error_message: success ? nil : determine_error(response)
      }
    rescue Faraday::TimeoutError
      {
        success: false,
        response_time_ms: monitor.timeout_seconds * 1000,
        error_message: "Request timed out after #{monitor.timeout_seconds}s",
        error_type: "timeout"
      }
    rescue Faraday::ConnectionFailed => e
      {
        success: false,
        error_message: e.message,
        error_type: "connection_refused"
      }
    rescue Faraday::SSLError => e
      {
        success: false,
        error_message: e.message,
        error_type: "ssl_error"
      }
    rescue => e
      {
        success: false,
        error_message: e.message,
        error_type: "exception"
      }
    end

    private

    def build_connection
      Faraday.new(url: monitor.url) do |f|
        f.options.timeout = monitor.timeout_seconds
        f.options.open_timeout = [10, monitor.timeout_seconds].min
        f.ssl.verify = monitor.verify_ssl

        # Add authentication
        apply_auth(f)

        # Add custom headers
        monitor.headers&.each { |k, v| f.headers[k] = v }

        # Follow redirects if configured
        if monitor.follow_redirects
          f.response :follow_redirects, limit: 5
        end

        f.adapter Faraday.default_adapter
      end
    end

    def make_request(conn)
      case monitor.http_method&.upcase
      when "POST"
        conn.post(nil, monitor.body)
      when "HEAD"
        conn.head
      when "PUT"
        conn.put(nil, monitor.body)
      when "DELETE"
        conn.delete
      when "PATCH"
        conn.patch(nil, monitor.body)
      else
        conn.get
      end
    end

    def apply_auth(conn)
      return unless monitor.auth_type.present?

      case monitor.auth_type
      when "basic"
        username = monitor.auth_config&.dig("username")
        password = monitor.auth_config&.dig("password")
        conn.request :authorization, :basic, username, password if username && password
      when "bearer"
        token = monitor.auth_config&.dig("token")
        conn.request :authorization, "Bearer", token if token
      when "header"
        header_name = monitor.auth_config&.dig("header_name")
        header_value = monitor.auth_config&.dig("header_value")
        conn.headers[header_name] = header_value if header_name && header_value
      end
    end

    def check_success(response)
      # Check status code
      return false unless response.status == monitor.expected_status

      # Check body content if specified
      if monitor.expected_body.present?
        return false unless response.body.to_s.include?(monitor.expected_body)
      end

      true
    end

    def determine_error(response)
      if response.status != monitor.expected_status
        "Expected status #{monitor.expected_status}, got #{response.status}"
      elsif monitor.expected_body.present? && !response.body.to_s.include?(monitor.expected_body)
        "Expected body to contain '#{monitor.expected_body}'"
      else
        "Unknown error"
      end
    end
  end
end
