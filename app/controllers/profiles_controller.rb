class ProfilesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile, only: [:show, :update])
  before_action(:check_permissions, except: [:index])

	def index
    profiles = Profile.by_name(params[:name])
      .by_therapist_id(params[:therapist_id])
      .by_active(params[:active])
      .by_role(params[:role])
      .allowed

		render_json_success({ profiles: profiles })
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
      render_success({ profile: @profile.show })
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
      return render_not_allowed() if !User.current.profile.allowed?
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:id])
    return render_json_errors("Perfil não encontrado!") if @profile.nil?
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
        :parent,
        :default_value,
        :extra,
        :role,
        :active,
        :therapist_id
      ).to_h.symbolize_keys
  end
end
