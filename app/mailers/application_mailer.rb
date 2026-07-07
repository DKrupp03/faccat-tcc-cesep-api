class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEVISE_MAILER_SENDER", "noreply@example.com")
  layout "mailer"
end
