class PasswordsController < Devise::PasswordsController
  respond_to(:json)

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      render_json_success()
    else
      render_json_errors(resource.errors.map(&:message))
    end
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      render_json_success()
    else
      render_json_errors(resource.errors.map(&:message))
    end
  end

  private

  def resource_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :reset_password_token
    )
  end
end
