class AnamnesesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_anamnese, only: [:show, :update])
  before_action(:check_permissions)

  def show
    render_json_success({ anamnese: @anamnese.show })
  end

  def create
    @anamnese = @profile.build_patient_anamnese(anamnese_params)

    if @anamnese.save
      render_json_success({ anamnese: @anamnese.show })
    else
      render_json_errors(@anamnese.errors)
    end
  end

  def update
     if @anamnese.update(anamnese_params)
      render_json_success({ anamnese: @anamnese.show })
    else
      render_json_errors(@anamnese.errors)
    end
  end

  private

  def check_permissions
    case params[:action]
    when "create"
      if !User.current.profile.admin? && @profile.therapist_id != User.current.profile_id
        return render_not_allowed()
      end
    when "update", "show"
      return render_not_allowed() if !@anamnese.allowed?
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    return render_not_found(Profile) if @profile.nil?
  end

  def set_anamnese
    @anamnese = @profile.patient_anamnese

    return render_not_found(Anamnese) if @anamnese.nil?
  end

  def anamnese_params
    params.require(:anamnese)
      .permit(
        :anamnese_type,
        :observations,
        :patient_id,
        :therapist_id,
        anamnese_data: {}
      ).to_h.symbolize_keys
  end
end
