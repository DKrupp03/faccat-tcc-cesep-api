class MedicalRecordsController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_record, only: [:show, :update, :destroy])
  before_action(:check_permissions)

	def index
    records = @profile.medical_records.includes(:service)
      .with_attached_attachments
      .by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .order(order_by)
      .allowed

    total = records.count

    if params[:page].present?
      records = records.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      medical_records: records.map(&:show),
      total: total
    })
	end

  def show
    render_json_success({ medical_record: @record.show })
  end

  def create
    @record = @profile.medical_records.new(record_params)

    if @record.save
      render_json_success({ medical_record: @record.show })
    else
      render_json_errors(@record.errors)
    end
  end

  def update
     if @record.update(record_params)
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

  def check_permissions
    case params[:action]
    when "index", "create"
      if !User.current.profile.admin? && @profile.therapist_id != User.current.profile_id
        return render_not_allowed()
      end
    when "update", "destroy", "show"
      return render_not_allowed() if !@record.allowed?
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    return render_not_found(Profile) if @profile.nil?
  end

  def set_record
    @record = @profile.medical_records.find_by_id(params[:id])

    return render_not_found(MedicalRecord) if @record.nil?
  end

  def filter_params
    return {} unless params[:records].present?

    params.permit(records: [
      :date_start,
      :date_end
    ])[:records].to_h.symbolize_keys
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

  def order_by
    case params[:order_by]
    when "date_start_asc"
      { date_start: :asc }
    when "date_start_desc"
      { date_start: :desc }
    else
      { date_start: :desc }
    end
  end
end
