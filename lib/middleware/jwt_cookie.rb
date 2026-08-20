# Transporta o JWT por cookie em vez do header Authorization, sem alterar o
# warden-jwt: na entrada copia o cookie para o header (para o warden validar) e
# na saída move o token que o warden-jwt emitiu no login para um cookie HttpOnly.
#
# Deve ser inserido ANTES de Warden::Manager (é a camada mais externa), assim
# roda antes do warden na entrada e depois dele na saída — vendo o header
# Authorization que o dispatch do login coloca na resposta.
#
# Fica em lib/middleware (fora do autoload) e é carregado por require em
# config/application.rb, pois é referenciado antes do Zeitwerk estar pronto.
class JwtCookie
  ACCESS_TOKEN = "access_token".freeze
  XSRF_TOKEN = "XSRF-TOKEN".freeze
  CSRF_SAFE_METHODS = %w[GET HEAD OPTIONS].freeze

  # Deve acompanhar jwt.expiration_time em config/initializers/devise.rb.
  MAX_AGE = 1.day.to_i

  def initialize(app)
    @app = app
  end

  def call(env)
    inject_token_from_cookie(env)

    forbidden = csrf_forbidden_response(env)
    return forbidden if forbidden

    status, headers, body = @app.call(env)

    request = Rack::Request.new(env)
    response = Rack::Response.new(body, status, headers)

    relocate_login_token(request, response)
    clear_on_logout(request, response)

    response.finish
  end

  private

  # Proteção CSRF (double-submit) no nível do Rack — antes de qualquer filtro de
  # controller (inclusive os prepends do Devise). Requisições mutantes
  # autenticadas por cookie precisam ecoar o cookie XSRF-TOKEN no header
  # X-XSRF-TOKEN. Sem o cookie de sessão (login/signup/senha) nada é exigido.
  # Retorna a resposta 403 (rack triple) quando viola; nil quando ok.
  def csrf_forbidden_response(env)
    return nil if CSRF_SAFE_METHODS.include?(env["REQUEST_METHOD"])

    req = Rack::Request.new(env)
    return nil if req.cookies[ACCESS_TOKEN].blank?

    header = env["HTTP_X_XSRF_TOKEN"]
    cookie = req.cookies[XSRF_TOKEN]
    return nil if header.present? && cookie.present? &&
                  Rack::Utils.secure_compare(header, cookie)

    body = { success: false, errors: [ I18n.t("activerecord.errors.messages.not_allowed") ] }.to_json
    [ 403, { "Content-Type" => "application/json" }, [ body ] ]
  end

  # Entrada: sem header Authorization, usa o cookie para autenticar via warden.
  def inject_token_from_cookie(env)
    return if env["HTTP_AUTHORIZATION"].present?

    token = Rack::Request.new(env).cookies[ACCESS_TOKEN]
    env["HTTP_AUTHORIZATION"] = "Bearer #{token}" if token.present?
  end

  # Saída do POST /login: move o token do header para cookie HttpOnly e emite o
  # cookie de CSRF (double-submit). O token deixa de ser exposto ao JavaScript.
  def relocate_login_token(request, response)
    return unless request.post? && request.path == "/login"

    auth = response.headers["Authorization"]
    return if auth.blank?

    token = auth.sub(/\ABearer /i, "")
    response.headers.delete("Authorization")

    set_cookie(response, ACCESS_TOKEN, token, http_only: true)
    set_cookie(response, XSRF_TOKEN, SecureRandom.urlsafe_base64(32), http_only: false)
  end

  # Saída do DELETE /logout: expira os cookies (o warden já revogou o jti).
  def clear_on_logout(request, response)
    return unless request.delete? && request.path == "/logout" && response.status < 400

    response.delete_cookie(ACCESS_TOKEN, path: "/")
    response.delete_cookie(XSRF_TOKEN, path: "/")
  end

  def set_cookie(response, name, value, http_only:)
    response.set_cookie(name, {
      value: value,
      path: "/",
      httponly: http_only,
      secure: Rails.env.production?,
      same_site: same_site,
      max_age: MAX_AGE
    })
  end

  # Lax quando front e API são same-site (default). Use None (com Secure) apenas
  # em deploy cross-site. O double-submit CSRF cobre os dois casos.
  def same_site
    ENV.fetch("COOKIE_SAMESITE", "Lax").downcase.to_sym
  end
end
