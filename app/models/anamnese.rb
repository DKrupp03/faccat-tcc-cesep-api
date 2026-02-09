class Anamnese < ApplicationRecord
  belongs_to(:patient, class_name: "User")
  belongs_to(:therapist, class_name: "User")

  validates(:anamnese_type, presence: true)
  validates(:anamnese_data, presence: true)
  validates(:patient_id, presence: true)
  validates(:therapist_id, presence: true)

  validate(:therapist_is_valid)
  validate(:patient_is_valid)

  enum(:anamnese_type, { child: 0, adolescent: 1, adult: 2 })

  private

  def therapist_is_valid
    unless User.exists?(id: therapist_id, user_type: :therapist)
      errors.add(:therapist_id, "Teraputa inválido!")
    end
  end

  def patient_is_valid
    unless User.exists?(id: patient_id, user_type: :patient)
      errors.add(:patient_id, "Paciente inválido!")
    end
  end
end
