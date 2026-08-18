class ServiceRecurrence < ApplicationRecord
  MAX_OCCURRENCES = 366

  has_many(:services, foreign_key: :recurrence_id, dependent: :destroy)

  validates(:frequency, presence: true)
  validates(:end_type, presence: true)
  validates(:start_date, presence: true)
  validates(
    :repeat_interval,
    presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 99 }
  )
  validates(:end_date, presence: true, if: :by_date?)
  validates(
    :end_date,
    comparison: { greater_than_or_equal_to: :start_date },
    if: -> { by_date? && end_date.present? && start_date.present? }
  )
  validates(
    :occurrences,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than: 0,
      less_than_or_equal_to: MAX_OCCURRENCES,
      allow_nil: true
    },
    if: :by_occurrences?
  )
  validates(:weekday, presence: true, inclusion: { in: 0..6, allow_nil: true }, if: :weekly?)
  validates(:month_day, presence: true, inclusion: { in: 1..31, allow_nil: true }, if: :monthly?)
  validate(:dates_within_limit)

  enum(:frequency, { daily: 0, weekly: 1, monthly: 2 })
  enum(:end_type, { by_date: 0, by_occurrences: 1 })

  def show
    self.attributes
  end

  # Datas de cada ocorrência da série, respeitando a frequência, o intervalo e o
  # critério de fim (data ou quantidade). Sempre limitado a MAX_OCCURRENCES.
  def dates
    return [] if start_date.blank? || frequency.blank? || repeat_interval.to_i <= 0

    limit = by_occurrences? ? occurrences.to_i : MAX_OCCURRENCES + 1
    return [] if limit <= 0

    result = []
    current = first_date

    while current.present? && result.size < limit
      break if by_date? && (end_date.blank? || current > end_date)

      result << current
      current = next_date(current)
    end

    result
  end

  # Monta (sem salvar) um atendimento por ocorrência, todos com os mesmos
  # atributos e apenas a data variando.
  def build_services(attributes)
    dates.map do |date|
      services.build(attributes.merge(date: date))
    end
  end

  private

  def first_date
    case frequency.to_sym
    when :daily
      start_date
    when :weekly
      return nil if weekday.blank?
      start_date + ((weekday.to_i - start_date.wday) % 7).days
    when :monthly
      return nil if month_day.blank?
      candidate = month_day_in(start_date)
      candidate < start_date ? month_day_in(start_date >> repeat_interval.to_i) : candidate
    end
  end

  def next_date(current)
    case frequency.to_sym
    when :daily
      current + repeat_interval.to_i.days
    when :weekly
      current + (repeat_interval.to_i * 7).days
    when :monthly
      month_day_in(current >> repeat_interval.to_i)
    end
  end

  # Dia do mês pedido dentro do mês da data informada, limitado ao último dia
  # do mês (ex.: dia 31 em fevereiro vira 28/29).
  def month_day_in(date)
    reference = date.beginning_of_month
    reference.change(day: [ month_day.to_i, reference.end_of_month.day ].min)
  end

  def dates_within_limit
    return if errors.any?

    if by_date? && dates.size > MAX_OCCURRENCES
      errors.add(:base, :too_many_occurrences, count: MAX_OCCURRENCES)
    elsif dates.empty?
      errors.add(:base, :no_occurrences)
    end
  end
end
