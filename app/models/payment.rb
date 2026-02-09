class Payment < ApplicationRecord
  belongs_to(:service)

  validates(:value, presence: true, numericality: { greater_than_or_equal_to: 0 })
  validates(:expiration_date, presence: true)
  validates(:payment_status, presence: true)
  validates(:service_id, presence: true)

  enum(:payment_method, { cash: 0, credit_card: 1, debit_card: 2, bank_slip: 3, bank_transfer: 4 })
  enum(:payment_status, { unpaid: 0, paid: 1, overdue: 2 })

  before_validation :set_payment_status

  private

  def set_payment_status
    return if expiration_date.blank?

    if payment_date.present?
      self.payment_status = :paid
    elsif expiration_date < Date.current
      self.payment_status = :overdue
    else
      self.payment_status = :unpaid
    end
  end
end
