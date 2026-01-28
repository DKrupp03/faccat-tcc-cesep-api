class User < ApplicationRecord
  has_many(:anamneses, foreign_key: :patient_id, dependent: :destroy)

  validates(:name, presence: true, uniqueness: { case_sensitive: true }, length: { minimum: 3, maximum: 50 })
  validates(:gender, presence: true)
  validates(:phone, presence: true)
  validates(:email, presence: true)
  validates(:birth, presence: true)
  validates(:cpf, presence: true)
  validates(:user_type, presence: true)

  enum(:gender, { other: 0, female: 1, male: 2 })
  enum(:user_type, { admin: 0, therapist: 1, patient: 2 })
end
