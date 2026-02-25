require "rails_helper"

RSpec.describe StatusSubscription, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:status_page) }
  end

  describe "validations" do
    subject { build(:status_subscription, :email) }

    it { is_expected.to validate_presence_of(:channel) }
    it { is_expected.to validate_inclusion_of(:channel).in_array(%w[email sms webhook]) }

    it "requires email when channel is email" do
      sub = build(:status_subscription, channel: "email", email: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:email]).to be_present
    end

    it "requires phone when channel is sms" do
      sub = build(:status_subscription, :sms, phone: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:phone]).to be_present
    end

    it "requires webhook_url when channel is webhook" do
      sub = build(:status_subscription, :webhook, webhook_url: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:webhook_url]).to be_present
    end
  end

  describe "scopes" do
    let(:page) { create(:status_page) }
    let!(:confirmed) { create(:status_subscription, :confirmed, status_page: page) }
    let!(:pending)   { create(:status_subscription, :pending,   status_page: page) }
    let!(:sms_sub)   { create(:status_subscription, :sms, :confirmed, status_page: page) }

    describe ".confirmed" do
      it "returns only confirmed subscriptions" do
        expect(StatusSubscription.confirmed).to include(confirmed, sms_sub)
        expect(StatusSubscription.confirmed).not_to include(pending)
      end
    end

    describe ".pending" do
      it "returns only unconfirmed subscriptions" do
        expect(StatusSubscription.pending).to include(pending)
        expect(StatusSubscription.pending).not_to include(confirmed)
      end
    end

    describe ".by_channel" do
      it "filters by channel type" do
        expect(StatusSubscription.by_channel("sms")).to include(sms_sub)
        expect(StatusSubscription.by_channel("sms")).not_to include(confirmed)
      end
    end
  end

  describe "callbacks" do
    it "generates a confirmation_token on create" do
      sub = create(:status_subscription, :email, status_page: create(:status_page))
      expect(sub.confirmation_token).to be_present
    end
  end

  describe "#confirm!" do
    let(:sub) { create(:status_subscription, :email, status_page: create(:status_page)) }

    it "marks the subscription as confirmed" do
      sub.confirm!
      expect(sub.reload.confirmed).to be true
    end

    it "sets confirmed_at" do
      Timecop.freeze do
        sub.confirm!
        expect(sub.reload.confirmed_at).to be_within(2.seconds).of(Time.current)
      end
    end

    it "clears the confirmation_token" do
      sub.confirm!
      expect(sub.reload.confirmation_token).to be_nil
    end
  end

  describe "#should_notify?" do
    let(:sub) { build(:status_subscription, severity_filter: %w[major critical]) }

    it "returns true when severity is in the filter" do
      expect(sub.should_notify?("major")).to be true
      expect(sub.should_notify?("critical")).to be true
    end

    it "returns false when severity is not in the filter" do
      expect(sub.should_notify?("minor")).to be false
    end
  end

  describe "#target" do
    it "returns email for email channel" do
      sub = build(:status_subscription, :email, email: "test@example.com")
      expect(sub.target).to eq("test@example.com")
    end

    it "returns phone for sms channel" do
      sub = build(:status_subscription, :sms, phone: "+15550000001")
      expect(sub.target).to eq("+15550000001")
    end

    it "returns webhook_url for webhook channel" do
      sub = build(:status_subscription, :webhook, webhook_url: "https://hooks.example.com/notify")
      expect(sub.target).to eq("https://hooks.example.com/notify")
    end
  end
end
