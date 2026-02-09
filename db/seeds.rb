timestamp = Time.now.to_i

admin = User.create(
  name: "Admin #{timestamp}",
  gender: :male,
  birth: Date.new(2003, 4, 28),
  user_type: :admin
)

therapist = User.create(
  name: "Terapeuta #{timestamp}",
  gender: :female,
  birth: Date.new(1985, 1, 1),
  user_type: :therapist
)

patient = User.create(
  name: "Paciente #{timestamp}",
  gender: :female,
  birth: Date.new(1985, 1, 1),
  user_type: :patient,
  therapist: therapist
)

service = Service.create(
  datetime_start: Time.current + 1.day,
  datetime_end: Time.current + 1.day + 1.hour,
  observations: "Observações do serviço",
  service_type: :clinical_psychology_tcc,
  service_status: :scheduled,
  patient: patient,
  therapist: therapist
)

payment = Payment.create(
  value: 100.00,
  expiration_date: Date.current + 30.days,
  service: service
)

patient_progress = PatientProgress.create(
  title: "Progresso do paciente",
  date: Date.current,
  observations: "Observações do progresso do paciente",
  service: service
)
