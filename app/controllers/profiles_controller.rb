class ProfilesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile, only: [:show, :update])
  before_action(:check_permissions, except: [:index])

	def index
    profiles = Profile.by_role(filter_params[:role])
    total = profiles.count

    total_active = profiles.by_active(1).count

    profiles = profiles.includes(:user, :patients, :patient_anamnese, :patient_services,
        :therapist, :therapist_anamneses, :therapist_services)
      .with_attached_photo
      .by_name(filter_params[:name])
      .by_active(filter_params[:active])
      .order(order_by)
      .allowed

    if filter_params[:role] == "patient"
      profiles = profiles.by_therapist_id(filter_params[:therapist_id])
        .by_payment_status(filter_params[:payment_status])
    elsif filter_params[:role] == "therapist"
      profiles = profiles.by_patient_id(filter_params[:patient_id])
    end

    total_filtered = profiles.count

    if params[:page].present?
      profiles = profiles.page(params[:page]).per(params[:per_page] || 30)
    end

		render_json_success({
      profiles: profiles.map { |p| p.show(list_attributes: true) },
      total_filtered: total_filtered,
      total: total,
      total_active: total_active,
    })
	end

  def show
    render_json_success({ profile: @profile.show })
  end

  def create
    @profile = Profile.new(profile_params)

    if @profile.save
      render_json_success({ profile: @profile.show })
    else
      render_json_errors(@profile.errors)
    end
  end

  def update
     if @profile.update(profile_params)
      render_json_success({ profile: @profile.show })
    else
      render_json_errors(@profile.errors)
    end
  end

  private

  def check_permissions
    case params[:action]
    when "create"
      return render_not_allowed() if !User.current.profile.admin?
    when "update", "show"
      return render_not_allowed() if !@profile.allowed?
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:id])

    return render_not_found(Profile) if @profile.nil?
  end

  def filter_params
    return {} unless params[:profiles].present?

    params.permit(profiles: [
      :name,
      :therapist_id,
      :patient_id,
      :active,
      :role,
      :payment_status
    ])[:profiles].to_h.symbolize_keys
  end

  def profile_params
    params.require(:profile)
      .permit(
        :name,
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
        :active,
        :therapist_id,
        :patient_id,
        :photo,
        parent: {},
      ).to_h.symbolize_keys
  end

  def order_by
    case params[:order_by]
    when "name_asc"
      { name: :asc }
    when "name_desc"
      { name: :desc }
    else
      { name: :asc }
    end
  end
end
