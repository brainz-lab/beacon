class StatusMailer < ApplicationMailer
  def confirmation(subscription)
    @subscription = subscription
    @status_page = subscription.status_page
    @confirm_url = confirm_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "Confirm your subscription to #{@status_page.name}"
    )
  end

  def incident_created(subscription, incident)
    @subscription = subscription
    @status_page = subscription.status_page
    @incident = incident
    @unsubscribe_url = unsubscribe_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "[#{severity_emoji(@incident.severity)}] #{@incident.title} - #{@status_page.name}"
    )
  end

  def incident_updated(subscription, incident, update)
    @subscription = subscription
    @status_page = subscription.status_page
    @incident = incident
    @update = update
    @unsubscribe_url = unsubscribe_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "[Update] #{@incident.title} - #{@status_page.name}"
    )
  end

  def incident_resolved(subscription, incident)
    @subscription = subscription
    @status_page = subscription.status_page
    @incident = incident
    @unsubscribe_url = unsubscribe_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "[Resolved] #{@incident.title} - #{@status_page.name}"
    )
  end

  def maintenance_scheduled(subscription, maintenance_window)
    @subscription = subscription
    @status_page = subscription.status_page
    @maintenance = maintenance_window
    @unsubscribe_url = unsubscribe_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "[Scheduled Maintenance] #{@maintenance.title} - #{@status_page.name}"
    )
  end

  def maintenance_starting(subscription, maintenance_window)
    @subscription = subscription
    @status_page = subscription.status_page
    @maintenance = maintenance_window
    @unsubscribe_url = unsubscribe_url(subscription)

    mail(
      to: subscription.endpoint,
      subject: "[Maintenance Starting] #{@maintenance.title} - #{@status_page.name}"
    )
  end

  private

  def confirm_url(subscription)
    "#{base_url}/status/#{@status_page.slug}/subscribe/confirm/#{subscription.confirmation_token}"
  end

  def unsubscribe_url(subscription)
    "#{base_url}/status/#{@status_page.slug}/unsubscribe/#{subscription.unsubscribe_token}"
  end

  def base_url
    Rails.application.config.action_mailer.default_url_options[:host] || "http://localhost:4006"
  end

  def severity_emoji(severity)
    case severity
    when "critical" then "🔴"
    when "major" then "🟠"
    when "minor" then "🟡"
    else "⚪"
    end
  end
end
