module Checkers
  class PingChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Use system ping command
      # -c 1 = one ping, -W = timeout in seconds
      timeout = monitor.timeout_seconds
      host = Shellwords.escape(monitor.host)

      # Platform-specific ping command
      command = if RUBY_PLATFORM =~ /darwin/
                  "ping -c 1 -W #{timeout * 1000} #{host}"
                else
                  "ping -c 1 -W #{timeout} #{host}"
                end

      # Execute ping
      output = `#{command} 2>&1`
      success = $?.success?

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i

      if success
        # Try to extract actual ping time from output
        ping_time = extract_ping_time(output)

        {
          success: true,
          response_time_ms: ping_time || response_time_ms
        }
      else
        {
          success: false,
          error_message: parse_error(output),
          error_type: "ping_failed"
        }
      end
    rescue => e
      {
        success: false,
        error_message: e.message,
        error_type: "exception"
      }
    end

    private

    def extract_ping_time(output)
      # Match patterns like "time=12.3 ms" or "time=12 ms"
      match = output.match(/time[=<](\d+\.?\d*)\s*ms/i)
      match ? match[1].to_f.round : nil
    end

    def parse_error(output)
      if output.include?("Unknown host") || output.include?("Name or service not known")
        "Unknown host: #{monitor.host}"
      elsif output.include?("Request timeout") || output.include?("100% packet loss")
        "Host unreachable: #{monitor.host}"
      elsif output.include?("Network is unreachable")
        "Network unreachable"
      else
        "Ping failed: #{output.lines.first&.strip || 'unknown error'}"
      end
    end
  end
end
