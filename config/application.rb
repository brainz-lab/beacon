require_relative "boot"

require "rails/all"

# Rails 8.1.1 compatibility fix for Solid Queue
# Add the `silence` method to Logger if it's missing
unless Logger.method_defined?(:silence)
  class Logger
    def silence(severity = Logger::ERROR)
      old_level = level
      self.level = severity
      yield
    ensure
      self.level = old_level
    end
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Beacon
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use SQL schema format for better TimescaleDB compatibility
    config.active_record.schema_format = :sql
  end
end
