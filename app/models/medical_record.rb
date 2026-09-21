class MedicalRecord < ApplicationRecord
  include Attachable

  belongs_to(:service)
  # Quem deu o visto: é sempre o supervisor do terapeuta do atendimento, mas
  # fica opcional porque o perfil pode ser excluído depois (FK com nullify).
  belongs_to(:reviewer, class_name: "Profile", optional: true)
  has_many_attached(:attachments)

  validates(:title, presence: true)
  validates(:date, presence: true)
  validates(:evolution, presence: true)
  # Sem `on: :create` a duplicata continuava possível trocando o service_id
  # numa edição (não há índice único no banco até a migration desta correção).
  validates(:service_id, uniqueness: true)

  def show
    record = self.attributes
    record.store(:attachments, attachments_json)
    record.store(:service, self.service)
    # Só id/nome do supervisor — o front monta o "Visto por Fulano em ...".
    record.store(:reviewer, self.reviewer&.summary)
    record
  end

  def self.by_date_start(date_start)
    return where("date >= ?", date_start) if date_start.present?
    all
  end

  def self.by_date_end(date_end)
    return where("date <= ?", date_end) if date_end.present?
    all
  end

  # O painel manda 1 (vistos), 0 (não vistos) ou -1 (todos), como no filtro de
  # situação dos perfis. Filtro ausente ou vazio também significa "todos".
  def self.by_reviewed(reviewed)
    return all if reviewed.blank?
    return all if reviewed.to_i.negative?
    where(reviewed: reviewed.to_i == 1)
  end

  # O visto é do supervisor do terapeuta que fez o atendimento — e só dele:
  # nem o próprio terapeuta nem o admin assinam a supervisão por ele.
  def reviewable_by?(profile = Current.profile)
    return false if profile.nil?
    self.service&.therapist&.supervisor_id == profile.id
  end

  # O visto carrega o par quem/quando, então a atribuição fica num ponto só.
  # E não se desfaz: uma vez assinado pelo supervisor, a marca e a autoria
  # ficam — daí só existir aqui o caminho de marcar. Um prontuário já visto
  # também ignora novo visto, para editar outros campos não reescrever a data.
  def apply_review(reviewed, reviewer = Current.profile)
    return if self.reviewed?
    return unless ActiveModel::Type::Boolean.new.cast(reviewed)

    self.reviewed = true
    self.reviewer = reviewer
    self.reviewed_at = Time.current
  end

  def self.allowed(profile = Current.profile)
    return none if profile.nil?
    return all if profile.admin?
    return joins(:service).where(services: { therapist_id: profile.team_ids }) if profile.therapist?
    none
  end

  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end
end
