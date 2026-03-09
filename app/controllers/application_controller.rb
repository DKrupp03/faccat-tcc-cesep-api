class ApplicationController < ActionController::API
  before_action(:set_current_user)
  before_action(:set_url_options)

  protected

  def set_current_user
    User.current = current_user if current_user
  end

  def set_url_options
    host = request.base_url
    ActiveStorage::Current.url_options = { host: host }
    Rails.application.routes.default_url_options[:host] = host
  end
  
  def render_json_success(response = {})
    response[:success] = true
    render(json: response)
  end

  def render_json_errors(errors)
    render(json: {
      success: false,
      errors: errors
    })
  end

  def render_not_allowed
    render_json_errors(
      I18n.t("activerecord.errors.messages.not_allowed")
    )
  end

  def render_not_found(model)
    render_json_errors(
      I18n.t("activerecord.errors.messages.not_found", model: model.model_name.human)
    )
  end
end
