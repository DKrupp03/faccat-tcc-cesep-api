class PatientProgress < ApplicationRecord
  belongs_to(:service)

  validates(:title, presence: true, length: { minimum: 3, maximum: 50 })
  validates(:date, presence: true)
  validates(:observations, presence: true)
  validates(:service_id, presence: true)
end
