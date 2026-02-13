class Service < ApplicationRecord
  belongs_to(:patient, class_name: "Profile")
  belongs_to(:therapist, class_name: "Profile")
  has_one(:patient_progress, dependent: :destroy)
  has_one(:payment, dependent: :destroy)

  validates(:datetime_start, presence: true, comparison: { greater_than_or_equal_to: -> { Time.current } })
  validates(:datetime_end, presence: true, comparison: { greater_than: :datetime_start })
  validates(:observations, presence: true)
  validates(:service_type, presence: true)
  validates(:service_status, presence: true)
  validates(:patient_id, presence: true)
  validates(:therapist_id, presence: true)

  validate(:therapist_is_valid)
  validate(:patient_is_valid)

  enum(:service_status, { scheduled: 0, confirmed: 1, attended: 2, no_show: 3, cancelled: 4 })
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

  private

  def therapist_is_valid
    unless Profile.exists?(id: therapist_id, role: :therapist)
      errors.add(:therapist_id, "Teraputa inválido!")
    end
  end

  def patient_is_valid
    unless Profile.exists?(id: patient_id, role: :patient)
      errors.add(:patient_id, "Paciente inválido!")
    end
  end
end
