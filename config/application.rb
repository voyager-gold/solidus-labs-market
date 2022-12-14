require_relative 'boot'

require 'rails/all'

require_relative 'initializers/redis'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

APP_HOST = ENV['HOST'] || (Rails.env.production? ? 'shoppn.com' : 'localhost' )

module SolidusMarket
  class Application < Rails::Application

    config.to_prepare do
      Dir.glob(File.join(File.dirname(__FILE__), '../lib/**/*.rb')) do |c|
        require_dependency(c)
      end

      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), '../app/**/*_decorator*.rb')) do |c|
        require_dependency(c)
      end

      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), '../app/overrides/*.rb')) do |c|
        require_dependency(c)
      end
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_controller.default_url_options = {
      host: APP_HOST
    }

    # Redis
    # config.cache_store = :redis_store, REDIS_CONFIG
  end
end
