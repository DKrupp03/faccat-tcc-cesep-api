class Payment < ApplicationRecord
  include Attachable

  belongs_to(:service)
  has_many_attached(:attachments)

  validates(:value, presence: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true })
  # O vencimento pode ser passado: a maioria dos pagamentos é lançada depois do
  # atendimento acontecer, e a trava anterior impedia registrar esse histórico.
  validates(:expiration_date, presence: true)
  # Recebimento no futuro entraria como "pago" e inflaria os totais e gráficos.
  validates(
    :payment_date,
    comparison: { less_than_or_equal_to: -> { Date.current } },
    allow_nil: true
  )
  # Sem `on: :create` a duplicata continuava possível trocando o service_id
  # numa edição (não há índice único no banco até a migration desta correção).
  validates(:service_id, uniqueness: true)

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
      .by_therapist_id(filters[:therapist_id])
      .by_payment_method(filters[:payment_method])
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

  def self.by_therapist_id(therapist_id)
    return joins(:service).where(services: { therapist_id: therapist_id }) if therapist_id.present?
    all
  end

  # Valor fora do enum viraria `payment_method IS NULL` e devolveria os
  # pagamentos sem forma de pagamento em vez de ignorar o filtro.
  def self.by_payment_method(payment_method)
    return all unless payment_methods.key?(payment_method.to_s)
    where(payment_method: payment_method)
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
    return none if profile.nil?
    return all if profile.admin?
    return joins(:service).where(services: { therapist_id: profile.id }) if profile.therapist?
    none
  end

  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end
end
