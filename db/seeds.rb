timestamp = Time.now.to_i
p "timestamp: #{timestamp}"

admin_profile = Profile.create!(
  name: "Admin #{timestamp}",
  gender: :male,
  birth: Date.new(2003, 4, 28),
  role: :admin
)

admin_user = User.new(
  email: "admin_#{timestamp}@example.com",
  password: "Admin123",
  password_confirmation: "Admin123",
  profile: admin_profile
)
admin_user.skip_confirmation!
admin_user.save!

therapist_profile = Profile.create!(
  name: "Terapeuta #{timestamp}",
  gender: :female,
  birth: Date.new(1985, 1, 1),
  role: :therapist
)

therapist_user = User.new(
  email: "therapist_#{timestamp}@example.com",
  password: "Therapist123",
  password_confirmation: "Therapist123",
  profile: therapist_profile
)
therapist_user.skip_confirmation!
therapist_user.save!

patient_profile = Profile.create!(
  name: "Paciente #{timestamp}",
  gender: :female,
  birth: Date.new(1985, 1, 1),
  role: :patient,
  therapist: therapist_profile
)

patient_user = User.new(
  email: "patient_#{timestamp}@example.com",
  password: "Patient123",
  password_confirmation: "Patient123",
  profile: patient_profile
)
patient_user.skip_confirmation!
patient_user.save!

service_observations = [
  "Sessão focada em ansiedade",
  "Acompanhamento psicológico",
  "Sessão de avaliação",
  "Discussão sobre progresso terapêutico",
  "Sessão de terapia cognitivo comportamental"
]

progress_titles = [
  "Sessão produtiva",
  "Discussão sobre emoções",
  "Trabalho em estratégias cognitivas",
  "Progresso no tratamento",
  "Reflexão sobre comportamentos"
]

progress_observations = [
  "Paciente apresentou melhora significativa.",
  "Sessão focada em identificação de gatilhos.",
  "Trabalhado técnicas de respiração.",
  "Paciente relatou avanços importantes.",
  "Sessão focada em reestruturação cognitiva."
]

10.times do |i|
  times = i * 7

  start_time = Time.current + rand(0..60).days + rand(8..18).hours
  end_time = start_time + [30, 45, 60, 90].sample.minutes

  service = Service.create!(
    datetime_start: start_time,
    datetime_end: end_time,
    observations: service_observations.sample,
    service_type: Service.service_types.keys.sample,
    status: Service.statuses.keys.sample,
    patient: patient_profile,
    therapist: therapist_profile
  )

  expiration = Date.current + rand(5..60).days
  paid = [true, false].sample

  payment = Payment.create!(
    value: rand(80.0..250.0).round(2),
    expiration_date: expiration,
    payment_date: paid ? expiration - rand(0..5).days : nil,
    payment_method: Payment.payment_methods.keys.sample,
    service: service
  )

  MedicalRecord.create!(
    title: progress_titles.sample,
    date: start_time.to_date,
    observations: progress_observations.sample,
    service: service
  )
end