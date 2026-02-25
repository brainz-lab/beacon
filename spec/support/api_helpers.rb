module ApiHelpers
  # Auth using bl_beacon_* key (api_key column)
  def auth_headers(project)
    { "Authorization" => "Bearer #{project.api_key}" }
  end

  # Auth using X-API-Key header
  def api_key_headers(project)
    { "X-API-Key" => project.api_key }
  end

  # Master key for project provisioning endpoints
  def master_key_headers(key = nil)
    key ||= ENV.fetch("BEACON_MASTER_KEY", "test_master_key_beacon")
    { "X-Master-Key" => key }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
