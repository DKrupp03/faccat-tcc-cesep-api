require "faker"

Faker::Config.locale = :en

# ─── Admin ─────────────────────────────────────────────────────────────────────

admin_profile = Profile.create!(
  name: "Admin",
  gender: :male,
  birth: Date.new(1980, 6, 15),
  role: :admin
)

admin_user = User.new(
  email: "admin@example.com",
  password: "Admin123",
  password_confirmation: "Admin123",
  profile: admin_profile
)
admin_user.skip_confirmation!
admin_user.save!

# ─── Terapeutas ────────────────────────────────────────────────────────────────

therapist_profiles = 20.times.map do |i|
  gender  = %i[male female].sample
  name    = gender == :female ? Faker::Name.feminine_name : Faker::Name.masculine_name
  profile = Profile.create!(
    name:   name,
    gender: gender,
    birth:  Faker::Date.birthday(min_age: 28, max_age: 60),
    role:   :therapist
  )
  user = User.new(
    email:                 "terapeuta#{i + 1}@example.com",
    password:              "Therapist123",
    password_confirmation: "Therapist123",
    profile:               profile
  )
  user.skip_confirmation!
  user.save!
  profile
end

# ─── Pacientes ─────────────────────────────────────────────────────────────────

patient_profiles = 100.times.map do |i|
  gender    = %i[male female].sample
  name      = gender == :female ? Faker::Name.feminine_name : Faker::Name.masculine_name
  therapist = therapist_profiles.sample
  profile   = Profile.create!(
    name:      name,
    gender:    gender,
    birth:     Faker::Date.birthday(min_age: 18, max_age: 70),
    role:      :patient,
    therapist: therapist
  )
  user = User.new(
    email:                 "paciente#{i + 1}@example.com",
    password:              "Patient123",
    password_confirmation: "Patient123",
    profile:               profile
  )
  user.skip_confirmation!
  user.save!
  profile
end

# ─── Conteúdo de sessões ───────────────────────────────────────────────────────

service_observations = [
  "Sessão focada em ansiedade e estratégias de regulação emocional",
  "Acompanhamento psicológico e revisão de metas terapêuticas",
  "Sessão de avaliação inicial e levantamento de histórico",
  "Discussão sobre progresso terapêutico e ajuste de plano",
  "Sessão de terapia cognitivo-comportamental",
  "Trabalho com técnicas de mindfulness e atenção plena",
  "Exposição gradual para fobia específica",
  "Psicoeducação sobre transtorno de humor",
  "Análise funcional de comportamentos problemáticos",
  "Reestruturação cognitiva de crenças disfuncionais",
  "Treinamento de habilidades sociais",
  "Sessão de relaxamento muscular progressivo",
  "Revisão de diário de pensamentos automáticos",
  "Trabalho com luto e elaboração de perdas",
  "Sessão de orientação familiar",
]

progress_titles = [
  "Sessão produtiva",
  "Discussão sobre emoções",
  "Trabalho em estratégias cognitivas",
  "Progresso no tratamento",
  "Reflexão sobre comportamentos",
  "Avanço nas técnicas de enfrentamento",
  "Revisão de objetivos terapêuticos",
  "Exploração de crenças centrais",
  "Trabalho com autoestima",
  "Consolidação de ganhos terapêuticos",
]

progress_observations = [
  "Paciente apresentou melhora significativa no controle da ansiedade.",
  "Sessão focada em identificação de gatilhos emocionais.",
  "Trabalhadas técnicas de respiração diafragmática.",
  "Paciente relatou avanços importantes nas relações interpessoais.",
  "Sessão focada em reestruturação cognitiva de pensamentos catastróficos.",
  "Paciente demonstrou maior autoconsciência emocional.",
  "Bom engajamento com as tarefas de casa propostas.",
  "Paciente relatou episódios de ansiedade reduzidos na semana.",
  "Trabalhadas habilidades de assertividade em situações de conflito.",
  "Paciente chegou motivado e disposto a explorar novas perspectivas.",
  "Foram discutidos padrões de relacionamento e seu impacto emocional.",
  "Paciente demonstrou resistência inicial, mas boa adesão ao longo da sessão.",
  "Progresso consistente; metas de curto prazo sendo alcançadas.",
  "Sessão encerrada com plano de ação claro para a semana.",
  "Paciente relatou boa aplicação das técnicas aprendidas no cotidiano.",
]

# ─── Atendimentos, Pagamentos e Prontuários ────────────────────────────────────

patient_profiles.each do |patient|
  therapist = patient.therapist

  rand(0..20).times do
    offset_days = rand(-180..90)
    start_time  = Time.current + offset_days.days + rand(8..17).hours + [0, 30].sample.minutes
    end_time    = start_time + [45, 60, 90].sample.minutes

    status = if offset_days < -7
               [ :attended, :no_show ].sample
             elsif offset_days < 0
               [ :attended, :cancelled ].sample
             else
               [ :scheduled, :confirmed ].sample
             end

    service = Service.new(
      datetime_start: start_time,
      datetime_end:   end_time,
      observations:   service_observations.sample,
      service_type:   Service.service_types.keys.sample,
      status:         status,
      patient:        patient,
      therapist:      therapist
    )
    service.save!(validate: false)

    paid_session = [ true, true, false ].sample
    expiration   = start_time.to_date + rand(1..15).days

    payment = Payment.new(
      value:           Faker::Commerce.price(range: 100.0..300.0),
      expiration_date: expiration,
      payment_date:    paid_session ? expiration - rand(0..5).days : nil,
      payment_method:  Payment.payment_methods.keys.sample,
      service:         service
    )
    payment.save!(validate: false)

    next unless status == :attended

    MedicalRecord.create!(
      title:        progress_titles.sample,
      date:         start_time.to_date,
      observations: progress_observations.sample,
      service:      service
    )
  end
end
