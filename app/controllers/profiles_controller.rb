class ProfilesController < ApplicationController
  # Papel, flag de admin e supervisor são sempre do admin: sem essa separação,
  # qualquer terapeuta se promovia (ou ganhava subordinados) editando o perfil.
  ADMIN_ONLY_ATTRIBUTES = [ :admin, :role, :supervisor_id ].freeze
  # Situação e vínculo o terapeuta ajusta, mas só em paciente seu — nunca no
  # próprio cadastro.
  PATIENT_ONLY_ATTRIBUTES = [ :active, :therapist_id ].freeze

  before_action(:authenticate_user!)
  before_action(:set_profile, only: [ :show, :update, :destroy ])
  before_action(:check_permissions, except: [ :index ])

  sortable(
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc },
    default: { name: :asc }
  )

  def index
    scoped = Profile.by_role(filter_params[:role]).allowed
    total = scoped.count

    # Todos os filtros do painel menos "situação": o card de ativos conta
    # quantos, dentro do recorte atual, estão ativos.
    filtered = scoped.includes(:user, :patients, :therapist, :supervisor,
        patient_services: :payment, therapist_services: :payment)
      .with_attached_photo
      .by_name(filter_params[:name])

    if filter_params[:role] == "patient"
      filtered = filtered.by_therapist_id(filter_params[:therapist_id])
        .by_payment_status(filter_params[:payment_status])
    elsif filter_params[:role] == "therapist"
      filtered = filtered.by_patient_id(filter_params[:patient_id])
    end

    total_active = filtered.by_active(1).count

    filtered = filtered.by_active(filter_params[:active]).order(order_by)
    total_filtered = filtered.count

    profiles = paginate(filtered)

    render_json_success({
      profiles: profiles.map { |p| p.show(list_attributes: true) },
      total_filtered: total_filtered,
      total: total,
      total_active: total_active
    })
  end

  def show
    render_json_success({ profile: @profile.show })
  end

  def create
    @profile = Profile.new(profile_params.except(:remove_photo))

    if @profile.save
      render_json_success({ profile: @profile.show(list_attributes: true) })
    else
      render_json_errors(@profile.errors)
    end
  end

  def update
    # O e-mail do perfil é o mesmo do login: alterar só um dos dois separava
    # silenciosamente o cadastro da credencial de acesso.
    Profile.transaction do
      @profile.update!(profile_params.except(:remove_photo))
      sync_user_email!
    end

    # Só depois do commit: o purge apaga o arquivo no storage e o rollback não
    # desfaz isso — a foto sumia mesmo quando a validação reprovava o resto.
    @profile.photo.purge if profile_params[:remove_photo].present?

    render_json_success({ profile: @profile.show(list_attributes: true) })
  rescue ActiveRecord::RecordInvalid => e
    render_json_errors(e.record.errors)
  end

  def destroy
    if @profile.destroy
      render_json_success()
    else
      render_json_errors(@profile.errors)
    end
  end

  private

  # Terapeuta cria e edita apenas pacientes do seu time (e o próprio perfil);
  # papel, flag de admin, supervisor e situação ficam restritos ao admin (ver
  # ADMIN_ONLY_ATTRIBUTES). Excluir perfil é sempre do admin: o destroy
  # cascateia usuário, atendimentos, pagamentos e prontuários.
  def check_permissions
    case params[:action]
    when "create"
      # Não-admin só cria paciente, e o paciente nasce vinculado ao time dele
      # (ver profile_params, que força role e therapist_id nesse caso).
      return render_not_allowed unless Current.profile.admin? || creating_patient?

      authorize_association!(Profile.therapist, profile_params[:therapist_id])
    when "show"
      authorize_record!(@profile)
    when "update"
      authorize_record!(@profile) &&
        authorize_therapist_update! &&
        authorize_association!(Profile.therapist, profile_params[:therapist_id])
    when "destroy"
      render_not_allowed unless Current.profile.admin?
    end
  end

  def creating_patient?
    params.dig(:profile, :role).to_s == "patient"
  end

  # O supervisor enxerga o perfil dos subordinados, mas cadastro de terapeuta
  # só o próprio (ou o admin) altera.
  def authorize_therapist_update!
    return true if Current.profile.admin? || @profile.patient? || @profile.id == Current.profile_id

    render_not_allowed
    false
  end

  # `skip_reconfirmation!` evita exigir confirmação do novo endereço: quem muda
  # é o terapeuta/admin pelo painel, não um visitante trocando o próprio login.
  def sync_user_email!
    user = @profile.user
    return if user.nil? || user.email == @profile.email

    user.skip_reconfirmation!
    user.update!(email: @profile.email)
  end

  def set_profile
    @profile = Profile.find_by_id(params[:id])

    render_not_found(Profile) if @profile.nil?
  end

  def filter_params
    nested_filter_params(:profiles, [
      :name,
      :therapist_id,
      :patient_id,
      :active,
      :role,
      :payment_status
    ])
  end

  def profile_params
    attributes = params.require(:profile)
      .permit(
        :name,
        :email,
        :gender,
        :birth,
        :address,
        :occupation,
        :marital_status,
        :education_level,
        :phone,
        :cpf,
        :rg,
        :crp,
        :default_value,
        :extra,
        :role,
        :admin,
        :active,
        :therapist_id,
        :supervisor_id,
        :patient_id,
        :photo,
        :remove_photo,
        parent: {},
      ).to_h.symbolize_keys

    Current.profile.admin? ? attributes : restrict_to_own_patients(attributes)
  end

  # Regras do terapeuta não-admin:
  # - nunca define admin, role nem supervisor (era assim que se promovia a admin);
  # - ao criar, o registro nasce como paciente do time (o terapeuta informado,
  #   se for ele ou um subordinado; senão, ele mesmo);
  # - ao editar paciente do time, ajusta situação e vínculo normalmente;
  # - ao editar o próprio cadastro, não mexe em situação nem vínculo.
  def restrict_to_own_patients(attributes)
    attributes = attributes.except(*ADMIN_ONLY_ATTRIBUTES)

    if params[:action] == "create"
      therapist_id = attributes[:therapist_id].to_i
      therapist_id = Current.profile_id unless Current.profile.team_ids.include?(therapist_id)
      return attributes.merge(role: :patient, therapist_id: therapist_id)
    end

    @profile&.patient? ? attributes : attributes.except(*PATIENT_ONLY_ATTRIBUTES)
  end
end
