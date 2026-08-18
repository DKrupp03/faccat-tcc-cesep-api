class RegistrationsController < Devise::RegistrationsController
  respond_to(:json)

  def create
    return create_patient_profile if requested_role == :patient

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

  # Paciente não acessa o sistema: cria apenas o perfil, sem User e sem e-mail de senha.
  def create_patient_profile
    profile = Profile.new(profile_params)

    if profile.save
      render_json_success({ profile: profile.show(list_attributes: true) })
    else
      render_json_errors(profile.errors)
    end
  end

  # Só o cadastro público envia role; qualquer valor fora da lista cai em terapeuta.
  def requested_role
    params.dig(:user, :profile, :role).to_s == "patient" ? :patient : :therapist
  end

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
    UserMailer.set_password_instructions(user, raw).deliver_now
  end

  PUBLIC_ATTRIBUTES = [
    :name, :email, :gender, :birth, :cpf, :crp, :rg, :phone, :address,
    :occupation, :marital_status, :education_level, :photo
  ].freeze
  # Só o admin cadastra vínculo, situação e a própria flag de admin — os dois
  # últimos, antes, eram silenciosamente ignorados mesmo vindos do painel.
  ADMIN_ATTRIBUTES = [ :admin, :active, :therapist_id, :default_value, :extra ].freeze

  # O mesmo endpoint atende o cadastro público (sem sessão) e a criação de
  # terapeuta pelo painel. Sem separar os campos, um visitante anônimo podia
  # pendurar um paciente na agenda de qualquer terapeuta.
  def profile_params
    attributes = PUBLIC_ATTRIBUTES
    attributes += ADMIN_ATTRIBUTES if current_user&.profile&.admin?

    params.require(:user).require(:profile)
      .permit(*attributes, parent: {})
      .merge(role: requested_role)
  end
end
