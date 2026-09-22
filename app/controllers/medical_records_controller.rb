class MedicalRecordsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_record, only: [ :show, :update, :destroy ])
  before_action(:check_permissions)

  # Cada papel escreve só a sua parte do prontuário: o terapeuta do
  # atendimento registra o que atendeu; o supervisor, a supervisão (mais o
  # visto, que passa pelo `assign_review`). O que vier fora disso é descartado
  # no `record_params` — o front já desabilita os campos, e recusar a
  # requisição inteira por um campo a mais só atrapalharia.
  THERAPIST_FIELDS = [ :title, :date, :evolution, :documentary_record, :service_id ].freeze
  SUPERVISOR_FIELDS = [ :supervision_record ].freeze

  sortable(
    "date_start_asc" => { date: :asc },
    "date_start_desc" => { date: :desc },
    default: { date: :desc }
  )

  def index
    # Parte de MedicalRecord.allowed (que já faz o join com services) em vez da
    # associação :through do perfil, que gerava um segundo join na mesma tabela.
    scoped = MedicalRecord.allowed
      .joins(:service)
      .where(services: { patient_id: @profile.id })

    # `total` é o do paciente e `total_filtered` o do recorte — mesmo contrato
    # dos demais painéis. Sem o segundo, o front não montava o "Carregar mais".
    total = scoped.count

    records = scoped
      .includes(:service, :reviewer)
      .with_attached_attachments
      .by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .by_reviewed(filter_params[:reviewed])
      .order(order_by)

    total_filtered = records.count
    records = paginate(records)

    render_json_success({
      medical_records: records.map(&:show),
      total: total,
      total_filtered: total_filtered
    })
  end

  def show
    render_json_success({ medical_record: @record.show })
  end

  def create
    # `@profile.medical_records` é has_many :through: construir por ela não
    # preenche o service_id (que vem do corpo e já foi autorizado acima).
    @record = MedicalRecord.new(record_params)
    assign_review(@record)

    if @record.save
      render_json_success({ medical_record: @record.show })
    else
      render_json_errors(@record.errors)
    end
  end

  def update
    remove_ids = @record.writable_by? ? removed_attachment_ids : []
    @record.attachments.where(id: remove_ids).find_each(&:purge) if remove_ids.any?

    attributes = record_params
    new_attachments = attributes.delete(:attachments)

    @record.assign_attributes(attributes)
    assign_review(@record)

    if @record.save
      @record.attachments.attach(new_attachments) if new_attachments.present?
      render_json_success({ medical_record: @record.show })
    else
      render_json_errors(@record.errors)
    end
  end

  def destroy
    if @record.destroy
      render_json_success({ medical_record: @record.show })
    else
      render_json_errors(@record.errors)
    end
  end

  private

  # Além do vínculo com o paciente da URL, o service_id do corpo precisa apontar
  # para um atendimento permitido e do próprio paciente — senão o prontuário
  # nasce pendurado no atendimento de outra pessoa.
  def check_permissions
    case params[:action]
    when "index"
      authorize_patient!
    when "create"
      authorize_patient! && authorize_service! && authorize_author!
    when "update"
      authorize_record!(@record) && authorize_service! && authorize_editor!
    when "destroy"
      authorize_record!(@record) && authorize_author!
    when "show"
      authorize_record!(@record)
    end
  end

  # Criar e excluir são atos do terapeuta do atendimento: ninguém escreve nem
  # apaga o prontuário no lugar dele — nem o supervisor, nem o admin.
  def authorize_author!
    return true if target_record.writable_by?

    render_not_allowed
    false
  end

  # Editar cabe ao terapeuta do atendimento e ao supervisor dele; o que cada
  # um altera é o `record_params` que recorta.
  def authorize_editor!
    return true if @record.writable_by? || @record.supervisable_by?

    render_not_allowed
    false
  end

  # O atendimento é quem define o papel de quem está pedindo: no create ele
  # vem do corpo; nas demais ações, é o do prontuário da URL.
  def target_record
    @target_record ||= @record || MedicalRecord.new(service_id: requested_service_id)
  end

  def requested_service_id
    params.require(:medical_record).permit(:service_id)[:service_id]
  end

  # O visto da supervisão fica fora do `permit`: quem não é o supervisor do
  # terapeuta do atendimento manda o campo à toa (o front o desabilita), e
  # ignorá-lo é melhor do que recusar a edição inteira do prontuário.
  def assign_review(record)
    reviewed = params.require(:medical_record).permit(:reviewed)[:reviewed]
    return if reviewed.nil?
    return unless record.reviewable_by?

    record.apply_review(reviewed)
  end

  def authorize_patient!
    authorize_team!(@profile.therapist_id)
  end

  # O atendimento informado precisa ser um atendimento permitido do próprio
  # paciente — e do próprio terapeuta: o prontuário nasce (ou se muda) só para
  # atendimento de quem o escreve, senão bastaria trocar o service_id para
  # pendurá-lo no atendimento de um colega.
  def authorize_service!
    service_id = record_params[:service_id]
    return true if service_id.blank?

    service = Service.allowed.find_by_id(service_id)

    if service.nil? || service.patient_id != @profile.id || service.therapist_id != Current.profile&.id
      render_not_allowed
      return false
    end

    true
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    render_not_found(Profile) if @profile.nil?
  end

  def set_record
    @record = @profile.medical_records.find_by_id(params[:id])

    render_not_found(MedicalRecord) if @record.nil?
  end

  def removed_attachment_ids
    params.require(:medical_record).permit(remove_attachment_ids: [])[:remove_attachment_ids] || []
  end

  def filter_params
    nested_filter_params(:medical_records, [
      :date_start,
      :date_end,
      :reviewed
    ])
  end

  def record_params
    @record_params ||= params.require(:medical_record)
      .permit(*permitted_fields)
      .to_h
      .symbolize_keys
  end

  # Anexos acompanham o registro do terapeuta: são documentos do atendimento,
  # não da supervisão.
  def permitted_fields
    return THERAPIST_FIELDS + [ { attachments: [] } ] if target_record.writable_by?
    return SUPERVISOR_FIELDS if target_record.supervisable_by?

    []
  end
end
