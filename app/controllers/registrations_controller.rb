class RegistrationsController < Devise::RegistrationsController
  respond_to(:json)

  protected

  def sign_up(resource_name, resource)
    # Não faz nada
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render(json: {
        user: {
          id: resource.id,
          email: resource.email
        }
      }, status: :ok)
    else
      render(json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity)
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :profile_id)
  end
end
