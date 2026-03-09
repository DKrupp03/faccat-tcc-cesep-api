class PatientProgress < ApplicationRecord
  belongs_to(:service)
  has_many_attached(:attachments)

  validates(:title, presence: true)
  validates(:date, presence: true)
  validates(:observations, presence: true)
  validates(:service, uniqueness: true, on: :create)

  def show
    progress = self.attributes
    progress.store(:attachment_urls, self.attachments.map { |a| rails_blob_url(a) })
    progress.store(:service, self.service)
    progress
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
    return joins(:service).where(services: { therapist_id: profile.id }) if profile.therapist?
    return all
  end

  def allowed?(profile = User.current.profile)
    return self.service.therapist_id == profile.id if profile.therapist?
    return true
  end
end
