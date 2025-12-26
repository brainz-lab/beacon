require "openssl"
require "socket"

module Checkers
  class SSLChecker < BaseChecker
    def perform_check
      uri = URI.parse(monitor.url)
      host = uri.host
      port = uri.port || 443

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Connect and get certificate
      tcp_client = TCPSocket.new(host, port)
      tcp_client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
      ssl_client.hostname = host
      ssl_client.connect

      cert = ssl_client.peer_cert
      chain = ssl_client.peer_cert_chain

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i

      ssl_client.close
      tcp_client.close

      # Analyze certificate
      expires_at = cert.not_after
      days_until_expiry = ((expires_at - Time.current) / 1.day).to_i
      is_valid = valid_certificate?(cert, days_until_expiry)

      # Update SSL certificate record
      update_ssl_certificate(cert, host)

      # Update monitor's SSL expiry
      monitor.update!(ssl_expiry_at: expires_at)

      {
        success: is_valid,
        response_time_ms: response_time_ms,
        tls_time_ms: response_time_ms,
        ssl_issuer: cert.issuer.to_s,
        ssl_expires_at: expires_at,
        ssl_valid: is_valid,
        error_message: certificate_error(cert, days_until_expiry)
      }
    rescue Errno::ECONNREFUSED
      {
        success: false,
        error_message: "Connection refused on port #{port}",
        error_type: "connection_refused"
      }
    rescue Errno::ETIMEDOUT, Timeout::Error
      {
        success: false,
        error_message: "Connection timed out",
        error_type: "timeout"
      }
    rescue OpenSSL::SSL::SSLError => e
      {
        success: false,
        error_message: e.message,
        error_type: "ssl_error"
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

    private

    def valid_certificate?(cert, days_until_expiry)
      cert.not_before <= Time.current &&
        cert.not_after >= Time.current &&
        days_until_expiry > 0
    end

    def certificate_error(cert, days_until_expiry)
      if days_until_expiry <= 0
        "Certificate has expired"
      elsif days_until_expiry <= (monitor.ssl_expiry_warn_days || 30)
        "Certificate expires in #{days_until_expiry} days"
      elsif cert.not_before > Time.current
        "Certificate is not yet valid"
      else
        nil
      end
    end

    def update_ssl_certificate(cert, domain)
      # Remove old certificate
      monitor.ssl_certificate&.destroy

      # Create new certificate record
      public_key = cert.public_key
      key_bits = public_key.respond_to?(:n) ? public_key.n.num_bits : nil

      monitor.create_ssl_certificate!(
        domain: domain,
        issuer: cert.issuer.to_s,
        subject: cert.subject.to_s,
        serial_number: cert.serial.to_s,
        issued_at: cert.not_before,
        expires_at: cert.not_after,
        valid: true,
        fingerprint_sha256: OpenSSL::Digest::SHA256.hexdigest(cert.to_der),
        public_key_algorithm: public_key.class.name.split("::").last,
        public_key_bits: key_bits,
        last_checked_at: Time.current
      )
    end
  end
end
