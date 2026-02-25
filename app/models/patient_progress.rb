class PatientProgress < ApplicationRecord
  belongs_to(:service)

  validates(:title, presence: true)
  validates(:date, presence: true)
  validates(:observations, presence: true)
  validates(:service_id, presence: true)

  def show
    progress = self.to_o
    progress.store(:service, self.service)
    progress
  end
end
