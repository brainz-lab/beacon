Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA support
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # API endpoints
  namespace :api do
    namespace :v1 do
      resources :monitors do
        member do
          post :pause
          post :resume
          post :check_now
          get :uptime
          get :response_times
        end

        resources :checks, only: [ :index ]
        resources :incidents, only: [ :index ]
        resources :alert_rules, only: [ :index, :create, :show, :update, :destroy ]
      end

      resources :incidents, only: [ :index, :show, :update ] do
        resources :updates, only: [ :index, :create ], controller: "incident_updates"
      end

      resources :status_pages do
        resources :monitors, controller: "status_page_monitors", only: [ :index, :create, :update, :destroy ] do
          collection do
            post :reorder
          end
        end
        resources :subscriptions, controller: "status_subscriptions", only: [ :index, :show, :destroy ]
      end

      resources :maintenance_windows
    end
  end

  # MCP endpoints
  scope :mcp do
    get "tools", to: "mcp/tools#index"
    post "tools/:name", to: "mcp/tools#call"
    post "rpc", to: "mcp/tools#rpc"
  end

  # Public status page
  get "status/:slug", to: "public/status#show", as: :public_status
  get "status/:slug/badge", to: "public/status#badge", as: :status_badge
  get "status/:slug/embed", to: "public/status#embed", as: :status_embed

  # Public subscriptions
  post "status/:slug/subscribe", to: "public/subscriptions#create", as: :public_subscribe
  get "status/:slug/subscribe/confirm/:token", to: "public/subscriptions#confirm", as: :confirm_subscription
  get "status/:slug/unsubscribe/:token", to: "public/subscriptions#destroy", as: :unsubscribe
  delete "status/:slug/unsubscribe/:token", to: "public/subscriptions#destroy"

  # Dashboard (web UI)
  namespace :dashboard do
    root to: "projects#index"

    resources :projects, only: [ :index, :new, :create ] do
      member do
        get :settings
      end

      # Nested under project
      get "/", to: "overview#index", as: :overview
      resources :monitors do
        member do
          post :pause
          post :resume
          post :check_now
        end
      end
      resources :incidents do
        resources :updates, only: [ :create ], controller: "incident_updates"
        member do
          post :resolve
        end
      end
      resources :status_pages do
        resources :monitors, controller: "status_page_monitors", only: [ :create, :update, :destroy ]
      end
      resources :maintenance_windows
      get "setup", to: "setup#index"
      get "mcp", to: "mcp_setup#index"
    end
  end

  # SSO callback
  get "sso/callback", to: "sso#callback"
  delete "sso/logout", to: "sso#logout"

  # Root redirect to dashboard
  root to: redirect("/dashboard")
end
