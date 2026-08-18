class AnamnesesController < ApplicationController
  before_action(:authenticate_user!)
  before_action(:set_profile)
  before_action(:set_anamnese, only: [ :show, :update ])
  before_action(:check_permissions)

  def show
    render_json_success({ anamnese: @anamnese.show })
  end

  def create
    return render_json_errors(I18n.t("activerecord.errors.models.anamnese.already_exists")) if @profile.anamnese

    @anamnese = @profile.build_anamnese(anamnese_params.merge(therapist_id: Current.profile_id))

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
      unless Current.profile.admin? || @profile.therapist_id == Current.profile_id
        render_not_allowed
      end
    when "update", "show"
      authorize_record!(@anamnese)
    end
  end

  def set_profile
    @profile = Profile.find_by_id(params[:profile_id])

    render_not_found(Profile) if @profile.nil?
  end

  def set_anamnese
    @anamnese = @profile.anamnese

    render_not_found(Anamnese) if @anamnese.nil?
  end

  # patient_id vem da URL (associação) e therapist_id da sessão: aceitá-los do
  # corpo só permitiria pendurar a anamnese em outra pessoa.
  def anamnese_params
    params.require(:anamnese)
      .permit(
        :anamnese_type,
        :observations,
        anamnese_data: {}
      ).to_h.symbolize_keys
  end
end
