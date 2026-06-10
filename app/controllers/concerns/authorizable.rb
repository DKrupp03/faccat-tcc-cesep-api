module Authorizable
  extend ActiveSupport::Concern

  private

  # Bloqueia a ação (render_not_allowed) a menos que o registro autorize o perfil
  # atual (Current.profile), conforme a regra `allowed?` de cada model.
  # Ponto único para, no futuro, registrar acessos negados (auditoria LGPD).
  def authorize_record!(record)
    render_not_allowed unless record.allowed?
  end
end
