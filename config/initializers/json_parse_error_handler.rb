class JsonParseErrorHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::Http::Parameters::ParseError
    [
      400,
      { "Content-Type" => "application/json" },
      [ { error: "Invalid JSON in request body" }.to_json ]
    ]
  end
end

Rails.application.config.middleware.insert_before 0, JsonParseErrorHandler
