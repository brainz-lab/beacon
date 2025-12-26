module Public
  class StatusController < ApplicationController
    skip_before_action :set_current_project
    skip_before_action :verify_authenticity_token

    # GET /status/:slug
    def show
      @status_page = StatusPage.find_by!(slug: params[:slug])

      return render json: { error: "Status page not found" }, status: :not_found unless @status_page.public?

      calculator = StatusCalculator.new(@status_page)

      render json: {
        name: @status_page.name,
        status: calculator.overall_status,
        status_info: calculator.status_info,
        components: calculator.component_statuses,
        groups: calculator.groups_with_statuses,
        active_incidents: @status_page.active_incidents.map { |i| incident_json(i) },
        recent_incidents: @status_page.recent_incidents.map { |i| incident_json(i) },
        overall_uptime: @status_page.overall_uptime,
        branding: branding_json(@status_page),
        updated_at: Time.current
      }
    end

    # GET /status/:slug/badge
    def badge
      @status_page = StatusPage.find_by!(slug: params[:slug])

      return render plain: "Not Found", status: :not_found unless @status_page.public?

      status = @status_page.calculate_status
      color = status_color(status)
      label = status_label(status)

      # Generate SVG badge
      svg = generate_badge_svg(label, color)

      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      response.headers["Content-Type"] = "image/svg+xml"
      render plain: svg
    end

    # GET /status/:slug/embed
    def embed
      @status_page = StatusPage.find_by!(slug: params[:slug])

      return render json: { error: "Not found" }, status: :not_found unless @status_page.public?

      calculator = StatusCalculator.new(@status_page)

      render json: {
        status: calculator.overall_status,
        status_info: calculator.status_info,
        overall_uptime: @status_page.overall_uptime,
        components_count: @status_page.monitors.count,
        active_incidents_count: @status_page.active_incidents.count
      }
    end

    private

    def incident_json(incident)
      {
        id: incident.id,
        title: incident.title,
        status: incident.status,
        severity: incident.severity,
        started_at: incident.started_at,
        resolved_at: incident.resolved_at,
        duration: incident.duration_humanized,
        updates: incident.updates.recent.limit(5).map do |u|
          {
            status: u.status,
            message: u.message,
            created_at: u.created_at
          }
        end
      }
    end

    def branding_json(status_page)
      {
        logo_url: status_page.logo_url,
        favicon_url: status_page.favicon_url,
        primary_color: status_page.primary_color,
        company_name: status_page.company_name,
        company_url: status_page.company_url,
        description: status_page.description,
        show_uptime: status_page.show_uptime,
        show_response_time: status_page.show_response_time,
        show_incidents: status_page.show_incidents,
        allow_subscriptions: status_page.allow_subscriptions
      }
    end

    def status_color(status)
      case status
      when "operational" then "#10B981"
      when "degraded" then "#F59E0B"
      when "partial_outage" then "#F97316"
      when "major_outage" then "#EF4444"
      else "#9CA3AF"
      end
    end

    def status_label(status)
      case status
      when "operational" then "Operational"
      when "degraded" then "Degraded"
      when "partial_outage" then "Partial Outage"
      when "major_outage" then "Major Outage"
      else "Unknown"
      end
    end

    def generate_badge_svg(label, color)
      width = 100 + (label.length * 7)
      label_x = 60

      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="20">
          <linearGradient id="b" x2="0" y2="100%">
            <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
            <stop offset="1" stop-opacity=".1"/>
          </linearGradient>
          <mask id="a">
            <rect width="#{width}" height="20" rx="3" fill="#fff"/>
          </mask>
          <g mask="url(#a)">
            <rect width="50" height="20" fill="#555"/>
            <rect x="50" width="#{width - 50}" height="20" fill="#{color}"/>
            <rect width="#{width}" height="20" fill="url(#b)"/>
          </g>
          <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
            <text x="26" y="15" fill="#010101" fill-opacity=".3">status</text>
            <text x="26" y="14">status</text>
            <text x="#{label_x + (width - 50) / 2}" y="15" fill="#010101" fill-opacity=".3">#{label}</text>
            <text x="#{label_x + (width - 50) / 2}" y="14">#{label}</text>
          </g>
        </svg>
      SVG
    end
  end
end
