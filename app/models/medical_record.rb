class MedicalRecord < ApplicationRecord
  belongs_to(:service)
  has_many_attached(:attachments)

  validates(:title, presence: true)
  validates(:date, presence: true)
  validates(:observations, presence: true)
  validates(:service, uniqueness: true, on: :create)

  def show
    record = self.attributes
    record.store(:attachments, self.attachments.map do |a|
      { id: a.id, name: a.blob.filename.to_s, url: rails_blob_url(a) }
    end)
    record.store(:service, self.service)
    record
  end

  def self.by_date_start(date_start)
    return where("date >= ?", date_start) if date_start.present?
    return all
  end

  def self.by_date_end(date_end)
    return where("date <= ?", date_end) if date_end.present?
    return all
  end

  def self.allowed(profile = User.current.profile)
    return all if profile.admin?
    return joins(:service).where(services: { therapist_id: profile.id }) if profile.therapist?
    return joins(:service).where(services: { patient_id: profile.id }) if profile.patient?
    return all
  end

  def allowed?(profile = User.current.profile)
    return true if profile.admin?
    return self.service.therapist_id == profile.id if profile.therapist?
    return self.service.patient_id == profile.id if profile.patient?
    return true
  end
end
