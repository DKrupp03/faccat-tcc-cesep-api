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

therapists_data = [
  { name: "Ana Souza",       gender: :female, birth: Date.new(1978, 3, 12), email: "ana.souza@example.com",       password: "Therapist123" },
  { name: "Carlos Mendes",   gender: :male,   birth: Date.new(1982, 7, 22), email: "carlos.mendes@example.com",   password: "Therapist123" },
  { name: "Fernanda Lima",   gender: :female, birth: Date.new(1990, 11, 5), email: "fernanda.lima@example.com",   password: "Therapist123" },
  { name: "Ricardo Alves",   gender: :male,   birth: Date.new(1975, 1, 30), email: "ricardo.alves@example.com",   password: "Therapist123" },
  { name: "Mariana Costa",   gender: :female, birth: Date.new(1988, 9, 18), email: "mariana.costa@example.com",   password: "Therapist123" },
]

therapist_profiles = therapists_data.map do |data|
  profile = Profile.create!(
    name: data[:name],
    gender: data[:gender],
    birth: data[:birth],
    role: :therapist
  )
  user = User.new(
    email: data[:email],
    password: data[:password],
    password_confirmation: data[:password],
    profile: profile
  )
  user.skip_confirmation!
  user.save!
  profile
end

# keep the canonical "therapist@example.com" alias pointing to the first therapist
therapist_profile = therapist_profiles.first

# ─── Pacientes ─────────────────────────────────────────────────────────────────

patients_data = [
  { name: "Julia Ferreira",   gender: :female, birth: Date.new(1995, 4, 10), email: "julia.ferreira@example.com" },
  { name: "Pedro Oliveira",   gender: :male,   birth: Date.new(1988, 8, 25), email: "pedro.oliveira@example.com" },
  { name: "Camila Santos",    gender: :female, birth: Date.new(2000, 12, 3), email: "camila.santos@example.com"  },
  { name: "Lucas Pereira",    gender: :male,   birth: Date.new(1993, 6, 17), email: "lucas.pereira@example.com"  },
  { name: "Beatriz Rocha",    gender: :female, birth: Date.new(1997, 2, 28), email: "beatriz.rocha@example.com"  },
  { name: "Gabriel Torres",   gender: :male,   birth: Date.new(1985, 10, 9), email: "gabriel.torres@example.com" },
  { name: "Isabela Nunes",    gender: :female, birth: Date.new(2002, 7, 14), email: "isabela.nunes@example.com"  },
  { name: "Thiago Barbosa",   gender: :male,   birth: Date.new(1991, 3, 21), email: "thiago.barbosa@example.com" },
  { name: "Larissa Gomes",    gender: :female, birth: Date.new(1999, 5, 7),  email: "larissa.gomes@example.com"  },
  { name: "Mateus Cardoso",   gender: :male,   birth: Date.new(1987, 11, 30),email: "mateus.cardoso@example.com" },
  { name: "Amanda Ribeiro",   gender: :female, birth: Date.new(1994, 9, 2),  email: "amanda.ribeiro@example.com" },
  { name: "Felipe Martins",   gender: :male,   birth: Date.new(1996, 1, 19), email: "felipe.martins@example.com" },
  { name: "Natalia Dias",     gender: :female, birth: Date.new(2001, 6, 11), email: "natalia.dias@example.com"   },
  { name: "Bruno Carvalho",   gender: :male,   birth: Date.new(1983, 8, 4),  email: "bruno.carvalho@example.com" },
  { name: "Priscila Moreira", gender: :female, birth: Date.new(1998, 3, 26), email: "priscila.moreira@example.com" },
]

patient_profiles = patients_data.each_with_index.map do |data, i|
  therapist = therapist_profiles[i % therapist_profiles.size]
  profile = Profile.create!(
    name: data[:name],
    gender: data[:gender],
    birth: data[:birth],
    role: :patient,
    therapist: therapist
  )
  user = User.new(
    email: data[:email],
    password: "Patient123",
    password_confirmation: "Patient123",
    profile: profile
  )
  user.skip_confirmation!
  user.save!
  profile
end

# keep the canonical "patient@example.com" alias
patient_profile = patient_profiles.first

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

  rand(8..20).times do
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
      value:           rand(100.0..300.0).round(2),
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
