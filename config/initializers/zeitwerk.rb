# Ensure BaseController is loaded before its children during eager loading
Rails.autoloaders.main.on_setup do
  # Force load the BaseController first to prevent loading order issues
  require_relative "../../app/controllers/api/v1/base_controller"
end
