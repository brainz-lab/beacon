module Public
  class SubscriptionsController < ApplicationController
    skip_before_action :set_current_project
    skip_before_action :verify_authenticity_token

    # POST /status/:slug/subscribe
    def create
      @status_page = StatusPage.find_by!(slug: params[:slug])

      return render json: { error: "Subscriptions not allowed" }, status: :forbidden unless @status_page.allow_subscriptions
      unless channel_enabled?
        return render json: {
          error: "Channel '#{params[:channel]}' is not enabled for this status page",
          enabled_channels: @status_page.subscription_channels,
          hint: "Use one of the enabled channels: #{@status_page.subscription_channels.join(', ')}"
        }, status: :unprocessable_entity
      end

      endpoint_field = endpoint_field_for(params[:channel])
      return render json: { error: "Endpoint is required" }, status: :unprocessable_entity if params[:endpoint].blank?

      subscription = @status_page.status_subscriptions.find_or_initialize_by(
        channel: params[:channel],
        endpoint_field => params[:endpoint]
      )

      if subscription.new_record?
        subscription.notify_incidents = params.fetch(:notify_incidents, true)
        subscription.notify_maintenance = params.fetch(:notify_maintenance, true)
        subscription.save!

        # Send confirmation based on channel
        send_confirmation(subscription)

        render json: {
          success: true,
          message: confirmation_message(subscription.channel)
        }, status: :created
      elsif subscription.confirmed?
        render json: {
          success: true,
          message: "Already subscribed"
        }
      else
        # Resend confirmation
        send_confirmation(subscription)

        render json: {
          success: true,
          message: confirmation_message(subscription.channel)
        }
      end
    end

    # GET /status/:slug/subscribe/confirm/:token
    def confirm
      subscription = StatusSubscription.find_by!(confirmation_token: params[:token])

      subscription.confirm!

      if request.format.json?
        render json: {
          success: true,
          message: "Subscription confirmed"
        }
      else
        redirect_to public_status_path(slug: subscription.status_page.slug, subscribed: true)
      end
    end

    # DELETE /status/:slug/unsubscribe/:token
    # GET /status/:slug/unsubscribe/:token (for email links)
    def destroy
      subscription = StatusSubscription.find_by!(unsubscribe_token: params[:token])

      subscription.destroy!

      if request.format.json?
        render json: {
          success: true,
          message: "Unsubscribed successfully"
        }
      else
        redirect_to public_status_path(slug: subscription.status_page.slug, unsubscribed: true)
      end
    end

    private

    def channel_enabled?
      @status_page.subscription_channels.include?(params[:channel])
    end

    def confirmation_message(channel)
      case channel
      when "email"
        "Check your email to confirm subscription"
      when "sms"
        "Check your phone for confirmation code"
      when "webhook"
        "Webhook subscription activated"
      else
        "Subscription pending confirmation"
      end
    end

    def endpoint_field_for(channel)
      case channel
      when "email" then :email
      when "sms" then :phone
      when "webhook" then :webhook_url
      else :email
      end
    end

    def send_confirmation(subscription)
      case subscription.channel
      when "email"
        StatusMailer.confirmation(subscription).deliver_later
      when "sms"
        # SMS confirmation via Signal
        SignalClient.new.send_sms(
          subscription.phone,
          "Confirm your subscription: #{confirmation_url(subscription)}"
        )
      when "webhook"
        # Webhooks auto-confirm with test ping
        subscription.confirm!
        send_test_webhook(subscription)
      end
    end

    def confirmation_url(subscription)
      "#{request.base_url}/status/#{@status_page.slug}/subscribe/confirm/#{subscription.confirmation_token}"
    end

    def send_test_webhook(subscription)
      Faraday.post(subscription.webhook_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          event: "subscription.confirmed",
          status_page: @status_page.slug,
          timestamp: Time.current
        }.to_json
      end
    rescue => e
      Rails.logger.warn "Webhook test failed: #{e.message}"
    end
  end
end
