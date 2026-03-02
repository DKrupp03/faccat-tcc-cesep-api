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

10.times do |i|
  times = i * 7

  service = Service.create(
    datetime_start: Time.current + times.day,
    datetime_end: Time.current + times.day + 1.hour,
    observations: "Observações do serviço #{i}",
    service_type: :clinical_psychology_tcc,
    status: :scheduled,
    patient: patient_profile,
    therapist: therapist_profile
  )
  
  payment = Payment.create(
    value: 100.00,
    expiration_date: Date.current + (30 + times).days,
    service: service
  )
  
  patient_progress = PatientProgress.create(
    title: "Progresso do paciente #{i}",
    date: Date.current + times.day,
    observations: "Observações do progresso do paciente",
    service: service
  )
end

