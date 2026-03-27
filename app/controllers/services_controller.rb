class ServicesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_service, only: [:show, :update, :destroy])
  before_action(:check_permissions, except: [:index])

	def index
    services = Service.includes(:patient, :therapist, :medical_record, :payment)
      .by_status(filter_params[:status])
      .by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .by_patient_id(filter_params[:patient_id])
      .by_therapist_id(filter_params[:therapist_id])
      .by_service_type(filter_params[:service_type])
      .order(order_by)
      .allowed

    total = services.count

    if params[:page].present?
      services = services.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      services: services.map(&:show),
      total: total
    })
	end

  def show
    render_json_success({ service: @service.show })
  end

  def create
    @service = Service.new(service_params)

    if @service.save
      render_json_success({ service: @service.show })
    else
      render_json_errors(@service.errors)
    end
  end

  def update
     if @service.update(service_params)
      render_json_success({ service: @service.show })
    else
      render_json_errors(@service.errors)
    end
  end

  def destroy
    if @service.destroy
      render_json_success({ service: @service.show })
    else
      render_json_errors(@service.errors)
    end
  end

  private

  def check_permissions
    case params[:action]
    when "create"
      current_profile = User.current.profile
      return render_not_allowed() unless current_profile.admin? || current_profile.therapist?
      if current_profile.therapist?
        return render_not_allowed() if params.dig(:service, :therapist_id).to_i != current_profile.id
      end
    when "update", "destroy", "show"
      return render_not_allowed() if !@service.allowed?
    end
  end

  def set_service
    @service = Service.find_by_id(params[:id])

    return render_not_found(Service) if @service.nil?
  end

  def filter_params
    return {} unless params[:services].present?

    params.permit(services: [
      :date_start,
      :date_end,
      :patient_id,
      :therapist_id,
      :service_type,
      :status
    ])[:services].to_h.symbolize_keys
  end

  def service_params
    params.require(:service)
      .permit(
        :datetime_start,
        :datetime_end,
        :observations,
        :service_type,
        :status,
        :patient_id,
        :therapist_id
      ).to_h.symbolize_keys
  end

  def order_by
    case params[:order_by]
    when "datetime_start_asc"
      { datetime_start: :asc }
    when "datetime_start_desc"
      { datetime_start: :desc }
    else
      { datetime_start: :desc }
    end
  end
end
