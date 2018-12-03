require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Settings in config/environments/* take precedence over those specified here.
# Application configuration can go into files in config/initializers
# -- all .rb files in that directory are automatically loaded after loading
# the framework and any gems in your application.
module Markus
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version
    config.load_defaults 5.2

    # Configure sensitive parameters which will be filtered from the log file
    config.filter_parameters += [:password]

    # Set the timezone
    config.time_zone = 'Eastern Time (US & Canada)'

    # Use Resque for background jobs
    config.active_job.queue_adapter = :resque

    # Use json serializer for cookies
    config.action_dispatch.cookies_serializer = :json

    # Use RSpec as test framework
    config.generators do |g|
      g.test_framework :rspec
    end

    # Assets
    # Enable the asset pipeline.
    config.assets.enabled = true
    # Suppress logger output for asset requests.
    config.assets.quiet = true
    # Add Yarn node_modules folder to the asset load path.
    config.assets.paths << Rails.root.join('node_modules')
    # Precompile additional assets.
    config.assets.precompile = %w(manifest.js)

    # Configure responders gem flash keys.
    # NOTE: This didn't work when put in config/initializers/responders.rb.
    config.responders.flash_keys = [:success, :error]

    # Use per form CSRF tokens for all controllers
    Rails.configuration.action_controller.per_form_csrf_tokens = true

    # TODO review initializers 01 and 02
    # TODO review markus custom config format
    # TODO handle namespaces properly for app/lib
    # TODO migrate all javascript to webpack
    # TODO try precompiled assets in production
    # TODO database pool connections and unicorn workers
  end
end
