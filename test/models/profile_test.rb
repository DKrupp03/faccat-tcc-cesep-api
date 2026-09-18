require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  # Regressão: o auto-join virava "patients_profiles" e o WHERE saía com
  # "patients", nome que não existe na query — o filtro quebrava com 500.
  test "by_patient_id devolve o terapeuta do paciente informado" do
    therapist = create_therapist("ana@exemplo.com")
    other_therapist = create_therapist("bruno@exemplo.com")
    patient = create_patient("paciente@exemplo.com", therapist)

    result = Profile.by_patient_id(patient.id)

    assert_includes(result, therapist)
    assert_not_includes(result, other_therapist)
    assert_not_includes(result, patient)
  end

  test "by_patient_id sem valor não filtra nada" do
    therapist = create_therapist("ana2@exemplo.com")

    assert_includes(Profile.by_patient_id(nil), therapist)
    assert_includes(Profile.by_patient_id(""), therapist)
  end

  test "by_patient_id devolve vazio quando o paciente não tem terapeuta" do
    patient = create_patient("avulso@exemplo.com", nil)

    assert_empty(Profile.by_patient_id(patient.id))
  end

  private

  def create_therapist(email)
    Profile.create!(
      name: "Terapeuta #{email}",
      email: email,
      gender: :female,
      birth: 30.years.ago.to_date,
      role: :therapist
    )
  end

  def create_patient(email, therapist)
    Profile.create!(
      name: "Paciente #{email}",
      email: email,
      gender: :male,
      birth: 20.years.ago.to_date,
      role: :patient,
      therapist: therapist
    )
  end
end
