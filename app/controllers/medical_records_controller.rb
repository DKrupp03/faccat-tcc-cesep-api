class MedicalRecordsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_record, only: [ :show, :update, :destroy ])
  before_action(:check_permissions)

  sortable(
    "date_start_asc" => { date: :asc },
    "date_start_desc" => { date: :desc },
    default: { date: :desc }
  )

  def index
    # Parte de MedicalRecord.allowed (que já faz o join com services) em vez da
    # associação :through do perfil, que gerava um segundo join na mesma tabela.
    records = MedicalRecord.allowed
      .joins(:service)
      .where(services: { patient_id: @profile.id })
      .includes(:service)
      .with_attached_attachments
      .by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .order(order_by)

    total = records.count
    records = paginate(records)

    render_json_success({
      medical_records: records.map(&:show),
      total: total
    })
  end

  def show
    render_json_success({ medical_record: @record.show })
  end

  def create
    # `@profile.medical_records` é has_many :through: construir por ela não
    # preenche o service_id (que vem do corpo e já foi autorizado acima).
    @record = MedicalRecord.new(record_params)

    if @record.save
      render_json_success({ medical_record: @record.show })
    else
      render_json_errors(@record.errors)
    end
  end

  def update
    remove_ids = params.require(:medical_record).permit(remove_attachment_ids: [])[:remove_attachment_ids] || []
    @record.attachments.where(id: remove_ids).find_each(&:purge) if remove_ids.any?

    attributes = record_params
    new_attachments = attributes.delete(:attachments)

    if @record.update(attributes)
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
      authorize_patient! && authorize_service!
    when "update"
      authorize_record!(@record) && authorize_service!
    when "destroy", "show"
      authorize_record!(@record)
    end
  end

  def authorize_patient!
    return true if Current.profile.admin? || @profile.therapist_id == Current.profile_id

    render_not_allowed
    false
  end

  def authorize_service!
    service_id = record_params[:service_id]
    return true if service_id.blank?
    return true if Service.allowed.exists?(id: service_id, patient_id: @profile.id)

    render_not_allowed
    false
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    render_not_found(Profile) if @profile.nil?
  end

  def set_record
    @record = @profile.medical_records.find_by_id(params[:id])

    render_not_found(MedicalRecord) if @record.nil?
  end

  def filter_params
    nested_filter_params(:medical_records, [
      :date_start,
      :date_end
    ])
  end

  def record_params
    params.require(:medical_record)
      .permit(
        :title,
        :date,
        :observations,
        :service_id,
        attachments: []
      ).to_h.symbolize_keys
  end
end
