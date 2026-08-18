class Anamnese < ApplicationRecord
  belongs_to(:patient, class_name: "Profile")
  belongs_to(:therapist, class_name: "Profile")

  validates(:anamnese_type, presence: true)
  validates(:anamnese_data, presence: true)

  enum(:anamnese_type, { child: 0, adolescent: 1, adult: 2 })

  # Um paciente tem uma única anamnese (has_one em Profile). O índice único
  # cobria [therapist_id, patient_id], então trocar o terapeuta do paciente
  # permitia uma segunda anamnese e o has_one passava a devolver qualquer uma.
  validates(:patient_id, uniqueness: true)

  def show
    anamnese = self.attributes
    anamnese.store(:patient, self.patient&.summary)
    anamnese
  end

  def self.allowed(profile = Current.profile)
    return none if profile.nil?
    return all if profile.admin?
    return joins(:patient).where(patient: { therapist_id: profile.id }) if profile.therapist?
    none
  end

  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end
end
