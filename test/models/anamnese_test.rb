require "test_helper"

class AnamneseTest < ActiveSupport::TestCase
  # Regressão: o WHERE saía com o nome da associação ("patient") e o JOIN com o
  # da tabela ("profiles"), então a query nem rodava. Só afetava não-admin.
  test "allowed enxerga a anamnese dos pacientes do time e não a dos outros" do
    therapist = create_therapist("ana@exemplo.com")
    other_therapist = create_therapist("bruno@exemplo.com")

    mine = create_anamnese(therapist, "paciente.ana@exemplo.com")
    theirs = create_anamnese(other_therapist, "paciente.bruno@exemplo.com")

    allowed = Anamnese.allowed(therapist)

    assert_includes(allowed, mine)
    assert_not_includes(allowed, theirs)
  end

  test "allowed enxerga a anamnese dos pacientes dos subordinados" do
    supervisor = create_therapist("chefe@exemplo.com")
    subordinate = create_therapist("equipe@exemplo.com")
    subordinate.update!(supervisor: supervisor)

    anamnese = create_anamnese(subordinate, "paciente.equipe@exemplo.com")

    assert_includes(Anamnese.allowed(supervisor), anamnese)
  end

  test "allowed devolve tudo para admin e nada sem perfil" do
    therapist = create_therapist("ana2@exemplo.com")
    admin = create_therapist("admin@exemplo.com")
    admin.update!(admin: true)

    anamnese = create_anamnese(therapist, "paciente.ana2@exemplo.com")

    assert_includes(Anamnese.allowed(admin), anamnese)
    assert_empty(Anamnese.allowed(nil))
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

  def create_anamnese(therapist, patient_email)
    patient = Profile.create!(
      name: "Paciente #{patient_email}",
      email: patient_email,
      gender: :male,
      birth: 20.years.ago.to_date,
      role: :patient,
      therapist: therapist
    )

    Anamnese.create!(
      patient: patient,
      therapist: therapist,
      anamnese_type: :adult,
      anamnese_data: { "reason" => "primeira consulta" }
    )
  end
end
