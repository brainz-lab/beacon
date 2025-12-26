module Checkers
  class BaseChecker
    attr_reader :monitor, :region

    def initialize(monitor, region: nil)
      @monitor = monitor
      @region = region || Beacon.current_region
    end

    def check
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        result = perform_check

        CheckResult.create!(
          monitor: monitor,
          checked_at: Time.current,
          region: region,
          status: result[:success] ? "up" : "down",
          response_time_ms: result[:response_time_ms],
          dns_time_ms: result[:dns_time_ms],
          connect_time_ms: result[:connect_time_ms],
          tls_time_ms: result[:tls_time_ms],
          ttfb_ms: result[:ttfb_ms],
          status_code: result[:status_code],
          response_size_bytes: result[:response_size_bytes],
          error_message: result[:error_message],
          error_type: result[:error_type],
          ssl_issuer: result[:ssl_issuer],
          ssl_expires_at: result[:ssl_expires_at],
          ssl_valid: result[:ssl_valid],
          resolved_ip: result[:resolved_ip],
          resolved_ips: result[:resolved_ips]
        )
      rescue => e
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

        CheckResult.create!(
          monitor: monitor,
          checked_at: Time.current,
          region: region,
          status: "down",
          response_time_ms: (elapsed * 1000).to_i,
          error_message: e.message,
          error_type: "exception"
        )
      end
    end

    protected

    def perform_check
      raise NotImplementedError, "Subclasses must implement #perform_check"
    end

    def measure_time
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      [(elapsed * 1000).to_i, result]
    end
  end
end
