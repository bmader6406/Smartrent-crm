require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Crm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Enables or disables the escaping of HTML entities in JSON serialization. Defaults to true.
    config.active_support.escape_html_entities_in_json = true
    
    # allow array in params
    #config.action_dispatch.perform_deep_munge = false
    
    # custom app config
    config.assets.paths << Rails.root.join("app", "assets", "flash")
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.autoload_paths += Dir["#{config.root}/app/models/**/**", "#{config.root}/lib"]
    
    # rack-attack gem
    config.middleware.use Rack::Attack
    
    config.force_ssl = false
    
    # Session timeouts
    config.session_absolute_timeout_duration = 60*60*24 # in seconds
    config.session_inactivity_timeout_duration = 60*30  # in seconds

    # session timeout
    config.session_absolute_timeout_duration = 60*60*24 # in seconds
    config.session_inactivity_timeout_duration = 60*30  # in seconds

  end
end
