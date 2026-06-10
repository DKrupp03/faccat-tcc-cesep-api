class ApplicationController < ActionController::API
  include Authorizable
  include Sortable

  before_action(:set_current_user)
  before_action(:set_url_options)

  protected

  def set_current_user
    Current.user = current_user
  end

  def set_url_options
    host = request.base_url
    ActiveStorage::Current.url_options = { host: host }
    Rails.application.routes.default_url_options[:host] = host
  end

  def render_json_success(response = {}, status: :ok)
    response[:success] = true
    render(json: response, status: status)
  end

  def render_json_errors(errors, status: :unprocessable_entity)
    errors = errors.full_messages if errors.respond_to?(:full_messages)
    render(json: { success: false, errors: errors }, status: status)
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

  # Permite e normaliza filtros aninhados sob params[key] (ex.: params[:payments]).
  # Retorna {} quando o grupo não veio na requisição.
  def nested_filter_params(key, fields)
    return {} unless params[key].present?

    params.permit(key => fields)[key].to_h.symbolize_keys
  end
end
