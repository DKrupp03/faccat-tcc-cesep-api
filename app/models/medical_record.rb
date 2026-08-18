class MedicalRecord < ApplicationRecord
  include Attachable

  belongs_to(:service)
  has_many_attached(:attachments)

  validates(:title, presence: true)
  validates(:date, presence: true)
  validates(:observations, presence: true)
  # Sem `on: :create` a duplicata continuava possível trocando o service_id
  # numa edição (não há índice único no banco até a migration desta correção).
  validates(:service_id, uniqueness: true)

  def show
    record = self.attributes
    record.store(:attachments, attachments_json)
    record.store(:service, self.service)
    record
  end

  def self.by_date_start(date_start)
    return where("date >= ?", date_start) if date_start.present?
    all
  end

  def self.by_date_end(date_end)
    return where("date <= ?", date_end) if date_end.present?
    all
  end

  def self.allowed(profile = Current.profile)
    return none if profile.nil?
    return all if profile.admin?
    return joins(:service).where(services: { therapist_id: profile.id }) if profile.therapist?
    none
  end

  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end
end
