module Api
  module V1
    class StatusSubscriptionsController < BaseController
      before_action :set_status_page
      before_action :set_subscription, only: [:show, :destroy]

      # GET /api/v1/status_pages/:status_page_id/subscriptions
      def index
        subscriptions = @status_page.status_subscriptions

        case params[:status]
        when "confirmed"
          subscriptions = subscriptions.confirmed
        when "pending"
          subscriptions = subscriptions.pending
        end

        subscriptions = subscriptions.where(channel: params[:channel]) if params[:channel].present?
        subscriptions = subscriptions.order(created_at: :desc).limit(params.fetch(:limit, 100).to_i)

        render json: {
          subscriptions: subscriptions.map { |s| subscription_json(s) },
          summary: {
            total: @status_page.status_subscriptions.count,
            confirmed: @status_page.confirmed_subscriptions.count,
            by_channel: @status_page.status_subscriptions.group(:channel).count
          }
        }
      end

      # GET /api/v1/status_pages/:status_page_id/subscriptions/:id
      def show
        render json: subscription_json(@subscription, detailed: true)
      end

      # DELETE /api/v1/status_pages/:status_page_id/subscriptions/:id
      def destroy
        @subscription.destroy!
        head :no_content
      end

      private

      def set_status_page
        @status_page = current_project.status_pages.find(params[:status_page_id])
      end

      def set_subscription
        @subscription = @status_page.status_subscriptions.find(params[:id])
      end

      def subscription_json(subscription, detailed: false)
        data = {
          id: subscription.id,
          channel: subscription.channel,
          endpoint: masked_endpoint(subscription),
          confirmed: subscription.confirmed?,
          created_at: subscription.created_at
        }

        if detailed
          data.merge!(
            confirmed_at: subscription.confirmed_at,
            preferences: subscription.preferences,
            metadata: subscription.metadata
          )
        end

        data
      end

      def masked_endpoint(subscription)
        case subscription.channel
        when "email"
          email = subscription.endpoint
          local, domain = email.split("@")
          "#{local[0..1]}***@#{domain}"
        when "sms"
          phone = subscription.endpoint
          "***#{phone[-4..]}"
        when "webhook"
          uri = URI.parse(subscription.endpoint) rescue nil
          uri ? "#{uri.host}/***" : "***"
        else
          "***"
        end
      end
    end
  end
end
