class Payment < ApplicationRecord
  belongs_to(:service)

  validates(:value, presence: true, numericality: { greater_than_or_equal_to: 0 })
  validates(:expiration_date, presence: true)
  validates(
    :expiration_date,
    comparison: { greater_than_or_equal_to: -> { Date.current } },
    on: :create
  )
  validates(:service, uniqueness: true, on: :create)

  enum(:payment_method, {
    cash: 0,  pix: 1, credit_card: 2, debit_card: 3, bank_slip: 4, bank_transfer: 5,
  })

  def show
    payment = self.attributes
    payment.store(:service, self.service)
    payment.store(:status, self.status)
    payment
  end

  def status
    if self.payment_date.present?
      :paid
    elsif self.expiration_date.present? && self.expiration_date < Date.current
      :overdue
    else
      :unpaid
    end
  end

  def self.by_payment_date_start(payment_date_start)
    return where("payment_date >= ?", payment_date_start) if payment_date_start.present?
    return all
  end

  def self.by_payment_date_end(payment_date_end)
    return where("payment_date <= ?", payment_date_end) if payment_date_end.present?
    return all
  end

  def self.by_expiration_date_start(expiration_date_start)
    return where("expiration_date >= ?", expiration_date_start) if expiration_date_start.present?
    return all
  end

  def self.by_expiration_date_end(expiration_date_end)
    return where("expiration_date <= ?", expiration_date_end) if expiration_date_end.present?
    return all
  end

  def self.by_patient_id(patient_id)
    return joins(:service).where(services: { patient_id: patient_id }) if patient_id.present?
    return all
  end

  def self.by_status(status)
    case status&.to_sym
    when :paid
      where.not(payment_date: nil)
    when :overdue
      where(payment_date: nil).where("expiration_date < ?", Date.current)
    when :unpaid
      where(payment_date: nil).where("expiration_date >= ?", Date.current)
    else
      all
    end
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
