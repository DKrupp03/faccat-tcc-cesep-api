class Payment < ApplicationRecord
  belongs_to(:service)

  validates(:value, presence: true, numericality: { greater_than_or_equal_to: 0 })
  validates(
    :expiration_date,
    presence: true,
    comparison: { greater_than_or_equal_to: -> { Date.current } },
    if: :will_save_change_to_expiration_date?
  )
  validates(:service_id, presence: true)

  enum(:payment_method, { cash: 0, credit_card: 1, debit_card: 2, bank_slip: 3, bank_transfer: 4 })

  def show
    payment = self.to_o
    payment.store(:service, self.service)
    payment.store(:payment_status, self.payment_status)
    payment
  end

  def payment_status
    if self.payment_date.present?
      :paid
    elsif self.expiration_date.present? && self.expiration_date < Date.current
      :overdue
    else
      :unpaid
    end
  end

  def self.allowed(user: current_user)
    if user.therapist?
      joins(:service).where(services: { therapist_id: user.id })
    else
      all
    end
  end
end
