class UserMailer < ApplicationMailer
  def set_password_instructions(user, token)
    @user = user
    @token = token
    mail(to: user.email, subject: t(".subject"))
  end
end
