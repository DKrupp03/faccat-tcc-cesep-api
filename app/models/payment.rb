class Payment < ApplicationRecord
  include Attachable

  belongs_to(:service)
  has_many_attached(:attachments)

  validates(:value, presence: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true })
  validates(:expiration_date, presence: true)
  validates(
    :expiration_date,
    comparison: { greater_than_or_equal_to: -> { Date.current } },
    on: :create,
    if: -> { expiration_date.present? }
  )
  validates(:service, uniqueness: true, on: :create)

  enum(:payment_method, {
    cash: 0,  pix: 1, credit_card: 2, debit_card: 3, bank_slip: 4, bank_transfer: 5
  })

  def show
    payment = self.attributes
    payment.store(:attachments, attachments_json)
    payment.store(:service, self.service&.show)
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

  # Aplica de uma vez todos os filtros do painel sobre o escopo permitido.
  # Listagem e gráficos usam este método para enxergarem o mesmo conjunto.
  def self.filtrate(filters = {})
    allowed
      .by_status(filters[:status])
      .by_payment_date_start(filters[:payment_date_start])
      .by_payment_date_end(filters[:payment_date_end])
      .by_expiration_date_start(filters[:expiration_date_start])
      .by_expiration_date_end(filters[:expiration_date_end])
      .by_patient_id(filters[:patient_id])
  end

  # Os filtros usam condições em hash (e não SQL cru) para que as colunas saiam
  # qualificadas com a tabela: a listagem faz includes(service: :payment), que
  # traz "payments" duas vezes para a query e tornaria as colunas ambíguas.
  def self.by_payment_date_start(payment_date_start)
    return where(payment_date: payment_date_start..) if payment_date_start.present?
    all
  end

  def self.by_payment_date_end(payment_date_end)
    return where(payment_date: ..payment_date_end) if payment_date_end.present?
    all
  end

  def self.by_expiration_date_start(expiration_date_start)
    return where(expiration_date: expiration_date_start..) if expiration_date_start.present?
    all
  end

  def self.by_expiration_date_end(expiration_date_end)
    return where(expiration_date: ..expiration_date_end) if expiration_date_end.present?
    all
  end

  def self.by_patient_id(patient_id)
    return joins(:service).where(services: { patient_id: patient_id }) if patient_id.present?
    all
  end

  def self.by_status(status)
    case status&.to_sym
    when :paid
      where.not(payment_date: nil)
    when :overdue
      where(payment_date: nil).where(expiration_date: ...Date.current)
    when :unpaid
      where(payment_date: nil).where(expiration_date: Date.current..)
    else
      all
    end
  end

  def self.allowed(profile = Current.profile)
    return all if profile.admin?
    return joins(:service).where(services: { therapist_id: profile.id }) if profile.therapist?
    return joins(:service).where(services: { patient_id: profile.id }) if profile.patient?
    all
  end

  def allowed?(profile = Current.profile)
    return true if profile.admin?
    return self.service.therapist_id == profile.id if profile.therapist?
    return self.service.patient_id == profile.id if profile.patient?
    true
  end
end
