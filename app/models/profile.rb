class Profile < ApplicationRecord
  has_one(:user, dependent: :destroy)
  has_one_attached(:photo)

  belongs_to(:therapist, class_name: "Profile", optional: true)
  has_many(:patients, class_name: "Profile", foreign_key: :therapist_id, dependent: :nullify)

  has_one(:anamnese, class_name: "Anamnese", foreign_key: :patient_id, dependent: :destroy)

  has_many(:therapist_services, class_name: "Service", foreign_key: :therapist_id, dependent: :destroy)
  has_many(:patient_services, class_name: "Service", foreign_key: :patient_id, dependent: :destroy)

  has_many(:medical_records, through: :patient_services, source: :medical_record)

  MAX_AGE_IN_YEARS = 120

  # O Devise normaliza o e-mail do User; sem o mesmo tratamento aqui, "A@x.com"
  # passava na unicidade do Profile e estourava no índice único de users.
  normalizes(:email, with: ->(email) { email.strip.downcase })

  validates(:name, presence: true, length: { minimum: 3 })
  validates(
    :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  )
  validates(:gender, presence: true)
  validates(
    :birth,
    presence: true,
    comparison: {
      less_than: -> { Date.current },
      greater_than: -> { MAX_AGE_IN_YEARS.years.ago.to_date },
      allow_nil: true
    }
  )
  validates(:cpf, cpf: true, allow_blank: true)
  validates(:cpf, uniqueness: { case_sensitive: false }, allow_blank: true)
  # `patient?` (predicado do enum) tolera role nil; `role.to_sym` estourava
  # NoMethodError antes mesmo da validação de presença de :role rodar.
  validates(
    :default_value,
    numericality: { greater_than_or_equal_to: 0 },
    allow_nil: true,
    if: :patient?
  )
  validates(:role, presence: true)

  enum(:gender, { male: 0, female: 1, other: 2 })
  enum(:marital_status, { single: 0, married: 1, divorced: 2, widowed: 3 })
  enum(:education_level, { elementary_incomplete: 0, elementary_complete: 1, high_school_incomplete: 2,
    high_school_complete: 3, technical: 4, higher_education_incomplete: 5, higher_education_complete: 6,
    postgraduate: 7, masters: 8, doctorate: 9 })
  enum(:role, { therapist: 0, patient: 1 })

  # Terapeuta enxerga os demais terapeutas apenas para poder selecioná-los
  # (vínculo do paciente, agendamento). Fora isso o perfil alheio não pode
  # trafegar completo: CPF, RG, endereço e afins são dado pessoal (LGPD).
  def visible_in_full?(profile = Current.profile)
    return true if profile.nil? || profile.admin?
    self.id == profile.id || self.therapist_id == profile.id
  end

  def summary
    self.attributes.slice("id", "name", "role", "active")
  end

  def show(list_attributes: false)
    return summary unless visible_in_full?

    profile = self.attributes
    profile.store(:photo_url, rails_blob_url(self.photo)) if self.photo.attached?
    profile.store(:user, self.user&.slice(:id, :email, :profile_id))

    if list_attributes
      profile.store(:patients_count, self.patients.size) if self.therapist?
      profile.store(:therapist, self.therapist&.summary) if self.patient?

      profile.store(:services_count, self.services.size)
      profile.store(:last_service, self.last_service&.starts_at)
      profile.store(:payment_status, self.payment_status)
    else
      profile.store(:patients, self.patients.map(&:summary)) if self.therapist?
      profile.store(:services, self.services)
      profile.store(:photo, self.photo) if self.photo.attached?
      profile.store(:anamnese, self.anamnese) if self.anamnese
    end

    profile
  end

  def services
    if self.therapist?
      self.therapist_services
    else
      self.patient_services
    end
  end

  def last_service
    @last_service ||= self.services.max_by { |service| [ service.date, service.start_time ] }
  end

  def payment_status
    self.last_service&.payment&.status
  end

  def self.by_name(name)
    return where("name ILIKE ?", "%#{name}%") if name.present?
    all
  end

  def self.by_role(role)
    return where(role: role) if role.present?
    all
  end

  # O painel manda 1 (ativos), 0 (inativos) ou -1 (todos). Filtro ausente ou
  # vazio significa "todos" — antes caía em `active IS NULL` e zerava a lista.
  def self.by_active(active)
    return all if active.blank?
    return all if active.to_i.negative?
    where(active: active.to_i == 1)
  end

  def self.by_therapist_id(therapist_id)
    return where(therapist_id: therapist_id, role: :patient) if therapist_id.present?
    all
  end

  def self.by_patient_id(patient_id)
    return joins(:patients).where(patients: { id: patient_id }) if patient_id.present?
    all
  end

  PAYMENT_STATUS_FILTERS = %w[paid overdue unpaid no_payment].freeze

  # Filtra pelo status do pagamento do último atendimento do paciente. Os JOINs
  # são LEFT: com INNER, paciente sem atendimento (ou cujo último atendimento
  # não tem pagamento) sumia da listagem em vez de aparecer como "sem pagamento".
  def self.by_payment_status(payment_status)
    return all if payment_status.blank?
    return all unless PAYMENT_STATUS_FILTERS.include?(payment_status.to_s)

    last_services = Service
      .select("DISTINCT ON (patient_id) patient_id, id AS service_id")
      .order("patient_id, services.date DESC, services.start_time DESC")

    joined = joins("LEFT JOIN (#{last_services.to_sql}) last_svc ON last_svc.patient_id = profiles.id")
             .joins("LEFT JOIN payments ON payments.service_id = last_svc.service_id")

    case payment_status.to_sym
    when :paid
      joined.where.not(payments: { payment_date: nil })
    when :overdue
      joined
        .where(payments: { payment_date: nil })
        .where("payments.expiration_date < ?", Date.current)
    when :unpaid
      joined
        .where(payments: { payment_date: nil })
        .where("payments.expiration_date >= ?", Date.current)
    when :no_payment
      joined.where(payments: { id: nil })
    end
  end

  # Escopo visível para o perfil autenticado. Só quem acessa o sistema é
  # terapeuta (paciente não tem login), então o fallback é fechado: perfil
  # desconhecido não enxerga nada.
  def self.allowed(profile = Current.profile)
    return none if profile.nil?
    return all if profile.admin?
    return where("role = 0 OR therapist_id = :id", id: profile.id) if profile.therapist?
    none
  end

  # Derivado de `allowed` para que listagem e acesso a registro nunca discordem
  # (o index chegou a listar perfis que o show recusava).
  def allowed?(profile = Current.profile)
    self.class.allowed(profile).exists?(id: self.id)
  end
end
