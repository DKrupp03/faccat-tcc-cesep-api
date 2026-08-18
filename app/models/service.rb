class Service < ApplicationRecord
  # Escopos aceitos ao editar/excluir uma ocorrência de uma série recorrente.
  RECURRENCE_SCOPES = %w[single future all].freeze
  # Campos propagados para as demais ocorrências quando o escopo não é "single"
  # (a data é sempre individual de cada ocorrência).
  RECURRENCE_SHARED_ATTRIBUTES = [
    :patient_id, :therapist_id, :service_type, :status, :observations, :start_time, :end_time
  ].freeze
  # Situações que liberam o horário na agenda do terapeuta.
  RELEASED_STATUSES = %w[no_show cancelled].freeze

  belongs_to(:patient, class_name: "Profile")
  belongs_to(:therapist, class_name: "Profile")
  belongs_to(:recurrence, class_name: "ServiceRecurrence", optional: true)
  has_one(:medical_record, dependent: :destroy)
  has_one(:payment, dependent: :destroy)

  validates(:date, presence: true)
  # Só cobra data futura quando ela muda: editar um atendimento antigo (ex.: mudar
  # a situação para "atendido") não deve reclamar da data já passada.
  validates(
    :date,
    comparison: { greater_than_or_equal_to: -> { Date.current } },
    if: -> { date.present? && will_save_change_to_date? }
  )
  validates(:start_time, presence: true)
  validates(:end_time, presence: true, comparison: { greater_than: :start_time }, if: -> { start_time.present? })
  validates(:service_type, presence: true)
  validates(:status, presence: true)
  validate(:therapist_agenda_is_free)

  enum(:status, { scheduled: 0, confirmed: 1, attended: 2, no_show: 3, cancelled: 4 })
  enum(:service_type, {
    # Psicologia Clínica – Psicoterapias
    clinical_psychology_tcc: 0, clinical_psychology_psychoanalysis: 1,
    clinical_psychology_systemic: 2, clinical_psychology_humanistic: 3,

    psychological_emergency_care: 4, # Plantão Psicológico
    school_psychology: 5, # Psicologia Escolar
    forensic_psychology: 6, # Psicologia Jurídica
    community_psychology: 7, # Psicologia Comunitária
    emergency_and_disaster_psychology: 8, # Psicologia de Prevenção das Emergências e Desastres

    # Psicologia Organizacional
    organizational_psychology_career_guidance: 9, organizational_psychology_worker_health: 10
  })

  def show
    service = self.attributes
    # Colunas "time" chegariam ao front como "2000-01-01T14:00:00.000Z" e seriam
    # convertidas de fuso pelo navegador; por isso a hora vai como "HH:MM".
    service["start_time"] = self.start_time&.strftime("%H:%M")
    service["end_time"] = self.end_time&.strftime("%H:%M")
    # Só id/nome: o painel exibe o nome, e o perfil completo traria CPF, RG e
    # endereço de pessoas que o solicitante não necessariamente pode ver.
    service.store(:patient, self.patient&.summary)
    service.store(:therapist, self.therapist&.summary)
    service.store(:medical_record, self.medical_record)
    service.store(:payment, self.payment)
    service.store(:recurrence, self.recurrence&.show)
    service
  end

  def starts_at
    return nil if self.date.blank? || self.start_time.blank?
    self.date.in_time_zone + self.start_time.seconds_since_midnight.seconds
  end

  def ends_at
    return nil if self.date.blank? || self.end_time.blank?
    self.date.in_time_zone + self.end_time.seconds_since_midnight.seconds
  end

  # Ocorrências atingidas por uma edição/exclusão, conforme o escolhido na modal.
  def recurrence_siblings(scope)
    return Service.where(id: self.id) if self.recurrence_id.blank? || scope.to_s == "single"

    siblings = Service.where(recurrence_id: self.recurrence_id)
    return siblings.where("date >= ?", self.date) if scope.to_s == "future"
    siblings
  end

  def self.by_date_start(date_start)
    return where("date >= ?", date_start.to_date) if date_start.present?
    all
  end

  def self.by_date_end(date_end)
    return where("date <= ?", date_end.to_date) if date_end.present?
    all
  end

  def self.by_patient_id(patient_id)
    return where(patient_id: patient_id) if patient_id.present?
    all
  end

  def self.by_therapist_id(therapist_id)
    return where(therapist_id: therapist_id) if therapist_id.present?
    all
  end

  # Valor fora do enum vira `coluna IS NULL` no Rails e devolveria lista vazia
  # sem erro; aqui o filtro desconhecido é simplesmente ignorado.
  def self.by_service_type(service_type)
    return all unless service_types.key?(service_type.to_s)
    where(service_type: service_type)
  end

  def self.by_status(status)
    return all unless statuses.key?(status.to_s)
    where(status: status)
  end

  def self.without_payment(without_payment)
    return where.not(id: Payment.select(:service_id)) if ActiveModel::Type::Boolean.new.cast(without_payment)
    all
  end

  def self.without_medical_record(without_medical_record)
    return where.not(id: MedicalRecord.select(:service_id)) if ActiveModel::Type::Boolean.new.cast(without_medical_record)
    all
  end

  def self.allowed(profile = Current.profile)
    return none if profile.nil?
    return all if profile.admin?
    return where(therapist_id: profile.id) if profile.therapist?
    none
  end

  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end

  private

  # Impede dois atendimentos sobrepostos para o mesmo terapeuta no mesmo dia.
  # Sobreposição = um começa antes de o outro terminar, nos dois sentidos.
  def therapist_agenda_is_free
    return if therapist_id.blank? || date.blank? || start_time.blank? || end_time.blank?
    return if RELEASED_STATUSES.include?(status.to_s)

    conflicting = Service
      .where(therapist_id: therapist_id, date: date)
      .where.not(status: RELEASED_STATUSES)
      .where("start_time < ? AND end_time > ?", end_time, start_time)
    conflicting = conflicting.where.not(id: id) if persisted?

    errors.add(:base, :agenda_conflict) if conflicting.exists?
  end
end
