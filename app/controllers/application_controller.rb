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
      I18n.t("activerecord.errors.messages.not_allowed"),
      status: :forbidden
    )
  end

  def render_not_found(model)
    render_json_errors(
      I18n.t("activerecord.errors.messages.not_found", model: model.model_name.human),
      status: :not_found
    )
  end

  DEFAULT_PER_PAGE = 30
  MAX_PER_PAGE = 100

  # Pagina quando params[:page] veio; sem isso a listagem volta inteira
  # (o calendário de atendimentos depende desse comportamento).
  def paginate(scope)
    return scope if params[:page].blank?
    scope.page(params[:page]).per(per_page)
  end

  # Teto para o per_page: sem limite, um `per_page=100000` derruba a resposta.
  def per_page
    requested = params[:per_page].to_i
    return DEFAULT_PER_PAGE if requested <= 0

    [ requested, MAX_PER_PAGE ].min
  end

  # Permite e normaliza filtros aninhados sob params[key] (ex.: params[:payments]).
  # Retorna {} quando o grupo não veio na requisição.
  def nested_filter_params(key, fields)
    return {} unless params[key].present?

    params.permit(key => fields)[key].to_h.symbolize_keys
  end
end
