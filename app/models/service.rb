class Service < ApplicationRecord
  # Escopos aceitos ao editar/excluir uma ocorrência de uma série recorrente.
  RECURRENCE_SCOPES = %w[single future all].freeze
  # Campos propagados para as demais ocorrências quando o escopo não é "single"
  # (a data é sempre individual de cada ocorrência).
  RECURRENCE_SHARED_ATTRIBUTES = [
    :patient_id, :therapist_id, :service_type, :status, :observations, :start_time, :end_time
  ].freeze

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
    service.store(:patient, self.patient)
    service.store(:therapist, self.therapist)
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

  def self.by_service_type(service_type)
    return where(service_type: service_type) if service_type.present?
    all
  end

  def self.by_status(status)
    return where(status: status) if status.present?
    all
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
    return all if profile.admin?
    return by_therapist_id(profile.id) if profile.therapist?
    return by_patient_id(profile.id) if profile.patient?
    all
  end

  def allowed?(profile = Current.profile)
    return true if profile.admin?
    return self.therapist_id == profile.id if profile.therapist?
    return self.patient_id == profile.id if profile.patient?
    true
  end
end
