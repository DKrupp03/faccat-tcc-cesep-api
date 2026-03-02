class Service < ApplicationRecord
  belongs_to(:patient, class_name: "Profile")
  belongs_to(:therapist, class_name: "Profile")
  has_one(:patient_progress, dependent: :destroy)
  has_one(:payment, dependent: :destroy)

  validates(
    :datetime_start,
    presence: true,
    comparison: { greater_than_or_equal_to: -> { Time.current } },
    if: :will_save_change_to_datetime_start?
  )
  validates(:datetime_end, presence: true, comparison: { greater_than: :datetime_start })
  validates(:service_type, presence: true)
  validates(:status, presence: true)
  validates(:patient_id, presence: true)
  validates(:therapist_id, presence: true)

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
    service.store(:patient, self.patient)
    service.store(:therapist, self.therapist)
    service.store(:patient_progress, self.patient_progress)
    service.store(:payment, self.payment)
    service
  end

  def self.by_date_start(date_start)
    return where("datetime_start >= ?", date_start) if date_start.present?
    return all
  end

  def self.by_date_end(date_end)
    return where("datetime_end <= ?", date_end) if date_end.present?
    return all
  end

  def self.by_patient_id(patient_id)
    return where(patient_id: patient_id) if patient_id.present?
    return all
  end

  def self.by_therapist_id(therapist_id)
    return where(therapist_id: therapist_id) if therapist_id.present?
    return all
  end

  def self.by_service_type(service_type)
    return where(service_type: service_type) if service_type.present?
    return all
  end

  def self.by_status(status)
    return where(status: status) if status.present?
    return all
  end

  def self.allowed(profile = User.current.profile)
    return by_therapist_id(profile.id) if profile.therapist?
    return all
  end

  def allowed?(profile = User.current.profile)
    return self.therapist_id == profile.id if profile.therapist?
    return true
  end
end
