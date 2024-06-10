require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fdss
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Beijing"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_job.queue_adapter = :sidekiq
    config.fdss = ActiveSupport::OrderedOptions.new
    config.fds = ActiveSupport::OrderedOptions.new
  end
end

Rails.application.configure do
  config.fdss.storage_path = Rails.root.join("files").to_s
  config.fdss.temp_ext = ".fds.save_tmp"
  config.fds.wan_address = ENV.fetch("FDS_WAN_ADDRESS") { "http://examle.com" }
  config.fdss.lan_address = ENV.fetch("FDSS_LAN_ADDRESS") { "http://localhost" }
  config.fdss.wan_address = ENV.fetch("FDSS_WAN_ADDRESS") { "http://example.com" }
  config.fdss.serial = ENV.fetch("FDSS_SERIAL"){""}
  config.fdss.secret = ENV.fetch("FDSS_SECRET"){""}
  config.fdss.sign = ENV.fetch("FDSS_SIGN"){""}
end