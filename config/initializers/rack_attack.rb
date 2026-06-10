# Rate limiting e proteção contra força bruta.
#
# O backend é o Rails.cache (solid_cache em produção). Em desenvolvimento, sem
# cache habilitado (`bin/rails dev:cache`), o throttle não contabiliza — esperado.

# Tentativas de login por IP.
Rack::Attack.throttle("login/ip", limit: 10, period: 60.seconds) do |req|
  req.ip if req.post? && req.path == "/login"
end

# Pedidos de recuperação de senha por IP.
Rack::Attack.throttle("password/ip", limit: 5, period: 60.seconds) do |req|
  req.ip if req.post? && req.path == "/password"
end

# Cadastros por IP, para conter abuso.
Rack::Attack.throttle("signup/ip", limit: 5, period: 60.seconds) do |req|
  req.ip if req.post? && req.path == "/signup"
end

# Resposta JSON padrão quando o limite é excedido (mesmo contrato do restante da API).
Rack::Attack.throttled_responder = lambda do |_req|
  [
    429,
    { "Content-Type" => "application/json" },
    [ { success: false, errors: [ "Muitas tentativas. Aguarde alguns instantes e tente novamente." ] }.to_json ]
  ]
end
