class RegistrationsController < Devise::RegistrationsController
  respond_to(:json)

  def create
    ActiveRecord::Base.transaction do
      profile = Profile.new(profile_params)
      profile.save!

      password = generate_random_password
      build_resource(sign_up_params.merge(profile_id: profile.id, password: password, password_confirmation: password))
      resource.skip_confirmation!
      resource.save!
    end

    send_set_password_instructions(resource)

    yield resource if block_given?

    respond_with(resource, location: after_sign_up_path_for(resource))
  rescue ActiveRecord::RecordInvalid => e
    if resource&.errors&.any?
      render_json_errors(resource.errors)
    else
      render_json_errors(e.record.errors)
    end
  end

  protected

  def sign_up(resource_name, resource)
    # Não faz nada
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render_json_success({ profile: resource.profile.show(list_attributes: true) })
    else
      render_json_errors(resource.errors)
    end
  end

  def sign_up_params
    params.require(:user).permit(:email)
  end

  def generate_random_password
    "Aa1#{SecureRandom.hex(12)}"
  end

  def send_set_password_instructions(user)
    return unless user.persisted?

    raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_token = hashed
    user.reset_password_sent_at = Time.now.utc
    user.save(validate: false)
    UserMailer.set_password_instructions(user, raw).deliver_later
  end

  def profile_params
    params.require(:user).require(:profile).permit(
      :name, :email, :gender, :birth, :role, :cpf, :crp, :rg, :phone, :address,
      :occupation, :marital_status, :education_level, :default_value,
      :extra, :therapist_id, :photo, parent: {}
    )
  end
end
