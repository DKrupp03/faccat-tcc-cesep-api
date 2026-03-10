class RegistrationsController < Devise::RegistrationsController
  respond_to(:json)

  def create
    profile = Profile.new(profile_params)

    unless profile.save
      render_json_errors(profile.errors.full_messages) and return
    end

    build_resource(sign_up_params.merge(profile_id: profile.id))
    resource.save

    yield resource if block_given?

    respond_with(resource, location: after_sign_up_path_for(resource))
  end

  protected

  def sign_up(resource_name, resource)
    # Não faz nada
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render_json_success({ profile: resource.profile.show })
    else
      render_json_errors(resource.errors.full_messages)
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).require(:profile).permit(
      :name, :gender, :birth, :role, :cpf, :crp, :rg, :phone, :address,
      :occupation, :marital_status, :education_level, :default_value,
      :extra, :therapist_id, parent: {}
    )
  end
end
