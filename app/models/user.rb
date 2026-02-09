class User < ApplicationRecord
  belongs_to(:therapist, class_name: "User", optional: true)
  has_many(:patients, class_name: "User", foreign_key: :therapist_id)

  has_many(:therapist_anamneses, class_name: "Anamnese", foreign_key: :therapist_id, dependent: :nullify)
  has_one(:patient_anamnese, class_name: "Anamnese", foreign_key: :patient_id, dependent: :destroy)

  has_many(:therapist_services, class_name: "Service", foreign_key: :therapist_id, dependent: :nullify)
  has_many(:patient_services, class_name: "Service", foreign_key: :patient_id, dependent: :destroy)

  validates(:name, presence: true, uniqueness: { case_sensitive: true }, length: { minimum: 3, maximum: 50 })
  validates(:gender, presence: true)
  validates(:birth, presence: true)
  validates(:default_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true)
  validates(:user_type, presence: true)

  validate(:therapist_is_valid, if: -> { therapist_id.present? })

  enum(:gender, { male: 0, female: 1, other: 2 })
  enum(:marital_status, { single: 0, married: 1, divorced: 2, widowed: 3 })
  enum(:education_level, { elementary_incomplete: 0, elementary_complete: 1, high_school_incomplete: 2,
    high_school_complete: 3, technical: 4, higher_education_incomplete: 5, higher_education_complete: 6,
    postgraduate: 7, masters: 8, doctorate: 9 })
  enum(:user_type, { admin: 0, therapist: 1, patient: 2 })

  private

  def therapist_is_valid
    unless User.exists?(id: therapist_id, user_type: :therapist)
      errors.add(:therapist_id, "Teraputa inválido!")
    end
  end
end
