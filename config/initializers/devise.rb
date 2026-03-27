Devise.setup do |config|
  config.password_length = 8..100
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "noreply@example.com")
end
