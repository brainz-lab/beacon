require "resolv"

module Checkers
  class DNSChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Create resolver with timeout
      resolver = Resolv::DNS.new
      resolver.timeouts = monitor.timeout_seconds

      # Perform DNS lookup
      addresses = resolver.getaddresses(monitor.host)

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i

      resolver.close

      if addresses.any?
        {
          success: true,
          response_time_ms: response_time_ms,
          dns_time_ms: response_time_ms,
          resolved_ip: addresses.first.to_s,
          resolved_ips: addresses.map(&:to_s)
        }
      else
        {
          success: false,
          error_message: "No DNS records found for #{monitor.host}",
          error_type: "dns_error"
        }
      end
    rescue Resolv::ResolvError => e
      {
        success: false,
        error_message: e.message,
        error_type: "dns_error"
      }
    rescue Resolv::ResolvTimeout
      {
        success: false,
        error_message: "DNS resolution timed out after #{monitor.timeout_seconds}s",
        error_type: "timeout"
      }
    rescue => e
      {
        success: false,
        error_message: e.message,
        error_type: "exception"
      }
    end
  end
end
