class ServicesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_service, only: [ :show, :update, :destroy ])
  before_action(:check_permissions, except: [ :index ])

  sortable(
    "date_asc" => { date: :asc, start_time: :asc },
    "date_desc" => { date: :desc, start_time: :desc },
    default: { date: :desc, start_time: :desc }
  )

  def index
    services = Service.allowed
    total = services.count

    services = services.includes(:patient, :therapist, :medical_record, :payment, :recurrence)
      .by_status(filter_params[:status])
      .by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .by_patient_id(filter_params[:patient_id])
      .by_therapist_id(filter_params[:therapist_id])
      .by_service_type(filter_params[:service_type])
      .without_payment(filter_params[:without_payment])
      .without_medical_record(filter_params[:without_medical_record])
      .order(order_by)

    total_filtered = services.count

    if params[:page].present?
      services = services.page(params[:page]).per(params[:per_page] || 30)
    end

    render_json_success({
      services: services.map(&:show),
      total: total,
      total_filtered: total_filtered
    })
  end

  def show
    render_json_success({ service: @service.show })
  end

  def create
    return create_recurrent if recurrent?

    @service = Service.new(service_params)

    if @service.save
      render_json_success({ service: @service.show })
    else
      render_json_errors(@service.errors)
    end
  end

  def update
    attributes = service_params
    siblings = @service.recurrence_siblings(scope_param)

    # Fora do escopo "single" a data continua sendo de cada ocorrência: só os
    # campos comuns são propagados para a série.
    if siblings.count > 1
      shared = attributes.slice(*Service::RECURRENCE_SHARED_ATTRIBUTES)

      Service.transaction do
        siblings.each { |service| service.update!(service == @service ? attributes : shared) }
      end
    else
      @service.update!(attributes)
    end

    render_json_success({ service: @service.reload.show })
  rescue ActiveRecord::RecordInvalid => e
    render_json_errors(e.record.errors)
  end

  def destroy
    service = @service.show
    recurrence = @service.recurrence

    Service.transaction do
      @service.recurrence_siblings(scope_param).destroy_all
      recurrence.destroy! if recurrence.present? && recurrence.services.reload.empty?
    end

    render_json_success({ service: service })
  rescue ActiveRecord::RecordNotDestroyed => e
    render_json_errors(e.record.errors)
  end

  private

  def create_recurrent
    recurrence = ServiceRecurrence.new(recurrence_params.merge(start_date: service_params[:date]))

    unless recurrence.valid?
      return render_json_errors(recurrence.errors)
    end

    services = recurrence.build_services(service_params)
    invalid = services.find { |service| !service.valid? }

    return render_json_errors(invalid.errors) if invalid.present?

    # Os atendimentos foram montados pela associação, então são salvos junto.
    recurrence.save!

    @service = services.first
    render_json_success({ service: @service.show })
  rescue ActiveRecord::RecordInvalid => e
    render_json_errors(e.record.errors)
  end

  def recurrent?
    ActiveModel::Type::Boolean.new.cast(params.dig(:service, :recurrent))
  end

  def scope_param
    scope = params[:scope].to_s
    Service::RECURRENCE_SCOPES.include?(scope) ? scope : "single"
  end

  def check_permissions
    case params[:action]
    when "create"
      current_profile = Current.profile
      if !current_profile.admin? && params.dig(:service, :therapist_id) != current_profile.id
        render_not_allowed()
      end
    when "update", "destroy", "show"
      # No escopo múltiplo a ação atinge outras ocorrências: todas precisam ser permitidas.
      unauthorized = @service.recurrence_siblings(scope_param).find { |service| !service.allowed? }
      authorize_record!(unauthorized || @service)
    end
  end

  def set_service
    @service = Service.find_by_id(params[:id])

    render_not_found(Service) if @service.nil?
  end

  def filter_params
    nested_filter_params(:services, [
      :date_start,
      :date_end,
      :patient_id,
      :therapist_id,
      :service_type,
      :status,
      :without_payment,
      :without_medical_record
    ])
  end

  def service_params
    params.require(:service)
      .permit(
        :date,
        :start_time,
        :end_time,
        :observations,
        :service_type,
        :status,
        :patient_id,
        :therapist_id
      ).to_h.symbolize_keys
  end

  # O padrão da recorrência só é aceito na criação: na edição a série é imutável.
  def recurrence_params
    params.require(:service)
      .permit(recurrence: [
        :frequency,
        :repeat_interval,
        :end_type,
        :end_date,
        :occurrences,
        :weekday,
        :month_day
      ])
      .fetch(:recurrence, {})
      .to_h.symbolize_keys
  end
end
