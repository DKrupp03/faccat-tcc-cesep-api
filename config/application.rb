require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Carregado por require (não autoload): é referenciado na montagem do middleware,
# antes do Zeitwerk estar pronto. Ver config.autoload_lib(ignore: [... middleware]).
require_relative "../lib/middleware/jwt_cookie"

module TccCesep1
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Brasilia"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Transporta o JWT por cookie HttpOnly (em vez do header Authorization) para
    # tirá-lo do alcance do JavaScript. Fica como camada mais externa, envolvendo
    # o warden. Ver app/middleware/jwt_cookie.rb.
    config.middleware.insert_before Warden::Manager, JwtCookie

    config.i18n.available_locales = [ :"pt-BR", :en ]
    config.i18n.default_locale = :"pt-BR"
  end
end
