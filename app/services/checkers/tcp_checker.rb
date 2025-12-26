require "socket"

module Checkers
  class TCPChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Attempt TCP connection
      socket = Socket.tcp(
        monitor.host,
        monitor.port,
        connect_timeout: monitor.timeout_seconds
      )

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i

      socket.close

      {
        success: true,
        response_time_ms: response_time_ms,
        connect_time_ms: response_time_ms
      }
    rescue Errno::ECONNREFUSED
      {
        success: false,
        error_message: "Connection refused on port #{monitor.port}",
        error_type: "connection_refused"
      }
    rescue Errno::ETIMEDOUT, Timeout::Error
      {
        success: false,
        error_message: "Connection timed out after #{monitor.timeout_seconds}s",
        error_type: "timeout"
      }
    rescue Errno::EHOSTUNREACH
      {
        success: false,
        error_message: "Host unreachable: #{monitor.host}",
        error_type: "host_unreachable"
      }
    rescue SocketError => e
      {
        success: false,
        error_message: e.message,
        error_type: "dns_error"
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
