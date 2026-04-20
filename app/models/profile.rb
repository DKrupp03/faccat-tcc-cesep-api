class Profile < ApplicationRecord
  has_one(:user, dependent: :destroy)
  has_one_attached(:photo)

  belongs_to(:therapist, class_name: "Profile", optional: true)
  has_many(:patients, class_name: "Profile", foreign_key: :therapist_id)

  has_many(:therapist_anamneses, class_name: "Anamnese", foreign_key: :therapist_id, dependent: :nullify)
  has_one(:patient_anamnese, class_name: "Anamnese", foreign_key: :patient_id, dependent: :destroy)

  has_many(:therapist_services, class_name: "Service", foreign_key: :therapist_id, dependent: :nullify)
  has_many(:patient_services, class_name: "Service", foreign_key: :patient_id, dependent: :destroy)

  has_many(:medical_records, through: :patient_services, source: :medical_record)

  validates(:name, presence: true, length: { minimum: 3 })
  validates(:gender, presence: true)
  validates(:birth, presence: true, comparison: { less_than: -> { Date.current } })
  validates(
    :default_value,
    numericality: { greater_than_or_equal_to: 0 },
    allow_nil: true,
    if: -> { role.to_sym == :patient }
  )
  validates(:role, presence: true)

  enum(:gender, { male: 0, female: 1, other: 2 })
  enum(:marital_status, { single: 0, married: 1, divorced: 2, widowed: 3 })
  enum(:education_level, { elementary_incomplete: 0, elementary_complete: 1, high_school_incomplete: 2,
    high_school_complete: 3, technical: 4, higher_education_incomplete: 5, higher_education_complete: 6,
    postgraduate: 7, masters: 8, doctorate: 9 })
  enum(:role, { admin: 0, therapist: 1, patient: 2 })

  def show(list_attributes: false)
    profile = self.attributes
    profile.store(:photo_url, rails_blob_url(self.photo)) if self.photo.attached?
    profile.store(:user, self.user)

    if list_attributes
      profile.store(:patients_count, self.patients.count) if self.therapist?
      profile.store(:therapist, self.therapist) if self.patient?

      profile.store(:services_count, self.services.count)
      profile.store(:last_service, self.last_service&.datetime_start)
      profile.store(:payment_status, self.payment_status)
    else
      profile.store(:patients, self.patients) if self.therapist?
      profile.store(:services, self.services)
    end

    return profile
  end

  def services
    if self.therapist?
      self.therapist_services
    else
      self.patient_services
    end
  end

  def last_service
    self.services.order(datetime_start: :desc).first
  end

  def payment_status
    self.last_service&.payment&.status
  end

  def self.by_role(role)
    return where(role: role) if role.present?
    return all
  end

  def self.by_active(active)
    return where(active: active) if active.present?
    return all
  end

  def self.by_therapist_id(therapist_id)
    return where(therapist_id: therapist_id, role: :patient) if therapist_id.present?
    return all
  end

  def self.by_patient_id(patient_id)
    return where(patient_id: patient_id, role: :patient) if patient_id.present?
    return all
  end

  def self.allowed(profile = User.current.profile)
    return where("id = :id OR therapist_id = :id", id: profile.id) if profile.therapist?
    return where(id: profile.id) if profile.patient?
    return all
  end

  def allowed?(profile = User.current.profile)
    return self.id == profile.id || self.therapist_id == profile.id if profile.therapist?
    return self.id == profile.id if profile.patient?
    return true
  end
end
