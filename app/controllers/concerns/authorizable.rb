module Authorizable
  extend ActiveSupport::Concern

  private

  # Bloqueia a ação (render_not_allowed) a menos que o registro autorize o perfil
  # atual (Current.profile), conforme a regra `allowed?` de cada model.
  # Ponto único para, no futuro, registrar acessos negados (auditoria LGPD).
  # Devolve true quando liberou e false quando renderizou a negativa, para que
  # várias checagens possam ser encadeadas com && sem risco de duplo render.
  def authorize_record!(record)
    return true if record.allowed?

    render_not_allowed
    false
  end

  # Bloqueia a ação quando um id vindo do corpo da requisição aponta para um
  # registro fora do escopo permitido. Sem isso, o `permit` deixaria o cliente
  # associar recursos de outro terapeuta (ex.: um atendimento com o paciente
  # alheio, cujo perfil completo voltaria serializado na resposta).
  # Ids em branco não são checados aqui: a obrigatoriedade é das validações.
  def authorize_association!(klass, id)
    return true if id.blank?
    return true if klass.allowed.exists?(id: id)

    render_not_allowed
    false
  end

  # Bloqueia a ação quando o terapeuta informado não é do time do perfil atual
  # (ele próprio ou um subordinado direto, ver Profile#team_ids). Admin passa.
  def authorize_team!(therapist_id)
    return true if Current.profile.admin?
    return true if Current.profile.team_ids.include?(therapist_id.to_i)

    render_not_allowed
    false
  end
end
