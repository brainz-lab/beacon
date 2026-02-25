require "rails_helper"

RSpec.describe SSLCertificate, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:uptime_monitor) }
  end

  describe "validations" do
    subject { build(:ssl_certificate) }

    it { is_expected.to validate_presence_of(:domain) }
  end

  describe "scopes" do
    let(:monitor) { create(:uptime_monitor) }
    let!(:valid_cert)     { create(:ssl_certificate, :valid_cert, uptime_monitor: monitor) }
    let!(:expiring_cert)  { create(:ssl_certificate, :expiring_soon, uptime_monitor: create(:uptime_monitor)) }
    let!(:expired_cert)   { create(:ssl_certificate, :expired, uptime_monitor: create(:uptime_monitor)) }

    describe ".expiring_soon" do
      it "returns certs expiring within 30 days by default" do
        expect(SSLCertificate.expiring_soon).to include(expiring_cert)
        expect(SSLCertificate.expiring_soon).not_to include(valid_cert)
      end

      it "accepts a custom days threshold" do
        very_soon = create(:ssl_certificate, :critical, uptime_monitor: create(:uptime_monitor))
        expect(SSLCertificate.expiring_soon(7)).to include(very_soon)
        expect(SSLCertificate.expiring_soon(7)).not_to include(expiring_cert)
      end
    end

    describe ".expired" do
      it "returns only expired certs" do
        expect(SSLCertificate.expired).to include(expired_cert)
        expect(SSLCertificate.expired).not_to include(valid_cert)
      end
    end

    describe ".valid_certs" do
      it "returns only valid certs" do
        expect(SSLCertificate.valid_certs).to include(valid_cert, expiring_cert)
        expect(SSLCertificate.valid_certs).not_to include(expired_cert)
      end
    end
  end

  describe "#days_until_expiry" do
    it "returns the number of days until expiry" do
      cert = build(:ssl_certificate, expires_at: 30.days.from_now)
      expect(cert.days_until_expiry).to be_within(1).of(30)
    end

    it "returns nil when expires_at is not set" do
      cert = build(:ssl_certificate, expires_at: nil)
      expect(cert.days_until_expiry).to be_nil
    end
  end

  describe "#expiring_soon?" do
    it "returns true when expiry is within the threshold" do
      cert = build(:ssl_certificate, :expiring_soon)
      expect(cert.expiring_soon?(30)).to be true
    end

    it "returns false when expiry is beyond the threshold" do
      cert = build(:ssl_certificate, :valid_cert)
      expect(cert.expiring_soon?(30)).to be false
    end
  end

  describe "#expired?" do
    it "returns true for expired certificates" do
      cert = build(:ssl_certificate, :expired)
      expect(cert.expired?).to be true
    end

    it "returns false for valid certificates" do
      cert = build(:ssl_certificate, :valid_cert)
      expect(cert.expired?).to be false
    end
  end

  describe "#status" do
    it "returns 'invalid' for invalid certs" do
      cert = build(:ssl_certificate, :invalid)
      expect(cert.status).to eq("invalid")
    end

    it "returns 'expired' for expired certs" do
      cert = build(:ssl_certificate, :expired)
      expect(cert.status).to eq("expired")
    end

    it "returns 'critical' for certs expiring within 7 days" do
      cert = build(:ssl_certificate, :critical, valid: true)
      expect(cert.status).to eq("critical")
    end

    it "returns 'warning' for certs expiring within 30 days" do
      cert = build(:ssl_certificate, :expiring_soon, valid: true)
      expect(cert.status).to eq("warning")
    end

    it "returns 'valid' for healthy certificates" do
      cert = build(:ssl_certificate, :valid_cert)
      expect(cert.status).to eq("valid")
    end
  end

  describe "#issuer_name" do
    it "extracts CN from issuer string" do
      cert = build(:ssl_certificate, issuer: "CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US")
      expect(cert.issuer_name).to eq("Let's Encrypt Authority X3")
    end

    it "returns the full issuer when no CN is present" do
      cert = build(:ssl_certificate, issuer: "Unknown Issuer")
      expect(cert.issuer_name).to eq("Unknown Issuer")
    end

    it "returns nil when issuer is nil" do
      cert = build(:ssl_certificate, issuer: nil)
      expect(cert.issuer_name).to be_nil
    end
  end
end
