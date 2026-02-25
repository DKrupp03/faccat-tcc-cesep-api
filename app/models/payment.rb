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

  def payment_status
    if self.payment_date.present?
      return :paid
    elsif self.expiration_date.present? && self.expiration_date < Date.current
      return :overdue
    else
      return :unpaid
    end
  end
end
