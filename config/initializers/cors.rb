# Be sure to restart your server when you modify this file.

# Allow CORS for API requests
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-Request-Id" ]

    resource "/mcp/*",
      headers: :any,
      methods: [ :get, :post, :options ],
      expose: [ "X-Request-Id" ]

    resource "/status/*",
      headers: :any,
      methods: [ :get, :options ]
  end
end
