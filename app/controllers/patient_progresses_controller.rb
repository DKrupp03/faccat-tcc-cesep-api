class PatientProgressesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_progress, only: [:show, :update, :destroy])
  before_action(:check_permissions)

	def index
    progresses = @profile.patient_progresses.by_date_start(filter_params[:date_start])
      .by_date_end(filter_params[:date_end])
      .order(order_by)
      .allowed

    total = progresses.count

    if params[:page].present?
      progresses = progresses.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      progresses: progresses.map(&:show),
      total: total
    })
	end

  def show
    render_json_success({ progress: @progress.show })
  end

  def create
    @progress = @profile.patient_progresses.new(progress_params)

    if @progress.save
      render_json_success({ progress: @progress.show })
    else
      render_json_errors(@progress.errors)
    end
  end

  def update
     if @progress.update(progress_params)
      render_json_success({ progress: @progress.show })
    else
      render_json_errors(@progress.errors)
    end
  end

  def destroy
    if @progress.destroy
      render_json_success({ progress: @progress.show })
    else
      render_json_errors(@progress.errors)
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
      return render_not_allowed() if !@progress.allowed?
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    return render_not_found(Profile) if @profile.nil?
  end

  def set_progress
    @progress = @profile.patient_progresses.find_by_id(params[:id])

    return render_not_found(PatientProgress) if @progress.nil?
  end

  def filter_params
    return {} unless params[:progresses].present?

    params.permit(progresses: [
      :date_start,
      :date_end
    ])[:progresses].to_h.symbolize_keys
  end

  def progress_params
    params.require(:progress)
      .permit(
        :title,
        :date,
        :observations,
        :service_id
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
