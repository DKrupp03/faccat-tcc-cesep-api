require "test_helper"

# Regras de quem pode o quê no prontuário (as mesmas que o formulário do front
# aplica nos campos): o terapeuta do atendimento cria, edita o registro
# clínico e exclui; o supervisor dele só encosta na supervisão (visto e
# registros); os demais, inclusive o admin, apenas consultam.
class MedicalRecordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @supervisor = create_therapist("supervisora@example.com")
    @therapist = create_therapist("terapeuta@example.com", supervisor: @supervisor)
    @admin = create_therapist("admin@example.com", admin: true)
    @colleague = create_therapist("colega@example.com")

    @patient = Profile.create!(
      name: "Paciente Teste",
      email: "paciente@example.com",
      gender: :female,
      birth: 30.years.ago.to_date,
      role: :patient,
      therapist_id: @therapist.id
    )

    @service = create_service(@therapist, "08:00", "09:00")
    @free_service = create_service(@therapist, "10:00", "11:00")
    @colleague_service = create_service(@colleague, "12:00", "13:00")

    @record = MedicalRecord.create!(
      service: @service,
      title: "Sessão 1",
      date: Date.current,
      evolution: "Evolução inicial"
    )
  end

  # --------------------------------------------------------------------------
  # Criar
  # --------------------------------------------------------------------------

  test "terapeuta do atendimento cria o prontuário" do
    sign_in_as(@therapist)

    post(profile_medical_records_path(@patient), params: new_record_params)

    assert_response(:success)
    assert(MedicalRecord.exists?(service_id: @free_service.id))
  end

  test "supervisor não cria o prontuário do subordinado" do
    sign_in_as(@supervisor)

    post(profile_medical_records_path(@patient), params: new_record_params)

    assert_response(:forbidden)
    assert_not(MedicalRecord.exists?(service_id: @free_service.id))
  end

  test "admin não cria o prontuário" do
    sign_in_as(@admin)

    post(profile_medical_records_path(@patient), params: new_record_params)

    assert_response(:forbidden)
    assert_not(MedicalRecord.exists?(service_id: @free_service.id))
  end

  test "terapeuta não cria prontuário em atendimento de colega" do
    sign_in_as(@therapist)

    post(profile_medical_records_path(@patient), params: new_record_params(@colleague_service))

    assert_response(:forbidden)
    assert_not(MedicalRecord.exists?(service_id: @colleague_service.id))
  end

  test "supervisor não cria o visto junto com o prontuário" do
    sign_in_as(@supervisor)

    post(profile_medical_records_path(@patient), params: new_record_params.deep_merge(
      medical_record: { reviewed: true }
    ))

    assert_response(:forbidden)
  end

  test "prontuário não nasce com o visto" do
    sign_in_as(@therapist)

    post(profile_medical_records_path(@patient), params: new_record_params.deep_merge(
      medical_record: { reviewed: true }
    ))

    assert_response(:success)
    created = MedicalRecord.find_by(service_id: @free_service.id)
    assert_not(created.reviewed?)
    assert_nil(created.reviewer_id)
  end

  # --------------------------------------------------------------------------
  # Editar — terapeuta do atendimento
  # --------------------------------------------------------------------------

  test "terapeuta edita os campos do prontuário" do
    sign_in_as(@therapist)

    patch(record_path, params: { medical_record: { title: "Sessão 1 revisada", evolution: "Nova evolução" } })

    assert_response(:success)
    @record.reload
    assert_equal("Sessão 1 revisada", @record.title)
    assert_equal("Nova evolução", @record.evolution)
  end

  test "terapeuta não escreve os registros da supervisão" do
    sign_in_as(@therapist)

    patch(record_path, params: { medical_record: { title: "Outro título", supervision_record: "Escrevi pela supervisora" } })

    assert_response(:success)
    @record.reload
    assert_equal("Outro título", @record.title)
    assert_nil(@record.supervision_record)
  end

  test "terapeuta não dá o próprio visto" do
    sign_in_as(@therapist)

    patch(record_path, params: { medical_record: { reviewed: true } })

    assert_response(:success)
    @record.reload
    assert_not(@record.reviewed?)
    assert_nil(@record.reviewer_id)
  end

  test "terapeuta não muda o prontuário para atendimento de colega" do
    sign_in_as(@therapist)

    patch(record_path, params: { medical_record: { service_id: @colleague_service.id } })

    assert_response(:forbidden)
    assert_equal(@service.id, @record.reload.service_id)
  end

  # --------------------------------------------------------------------------
  # Editar — supervisor
  # --------------------------------------------------------------------------

  test "supervisor escreve os registros da supervisão e dá o visto" do
    sign_in_as(@supervisor)

    patch(record_path, params: { medical_record: { supervision_record: "Discutido em supervisão", reviewed: true } })

    assert_response(:success)
    @record.reload
    assert_equal("Discutido em supervisão", @record.supervision_record)
    assert(@record.reviewed?)
    assert_equal(@supervisor.id, @record.reviewer_id)
    assert_not_nil(@record.reviewed_at)
  end

  test "supervisor não edita os campos do terapeuta" do
    sign_in_as(@supervisor)

    patch(record_path, params: { medical_record: {
      title: "Título do supervisor",
      evolution: "Evolução do supervisor",
      documentary_record: "Registro do supervisor",
      service_id: @free_service.id,
      supervision_record: "Só isto entra"
    } })

    assert_response(:success)
    @record.reload
    assert_equal("Sessão 1", @record.title)
    assert_equal("Evolução inicial", @record.evolution)
    assert_nil(@record.documentary_record)
    assert_equal(@service.id, @record.service_id)
    assert_equal("Só isto entra", @record.supervision_record)
  end

  test "visto salvo não é desfeito nem pelo supervisor que o deu" do
    @record.update!(reviewed: true, reviewer: @supervisor, reviewed_at: Time.current)
    sign_in_as(@supervisor)

    patch(record_path, params: { medical_record: { reviewed: false } })

    assert_response(:success)
    assert(@record.reload.reviewed?)
    assert_equal(@supervisor.id, @record.reviewer_id)
  end

  test "supervisor de outro terapeuta não edita a supervisão" do
    sign_in_as(@colleague)

    patch(record_path, params: { medical_record: { supervision_record: "Não é minha supervisão" } })

    assert_response(:forbidden)
    assert_nil(@record.reload.supervision_record)
  end

  # --------------------------------------------------------------------------
  # Editar — admin
  # --------------------------------------------------------------------------

  test "admin não edita o prontuário" do
    sign_in_as(@admin)

    patch(record_path, params: { medical_record: { title: "Título do admin", supervision_record: "Supervisão do admin", reviewed: true } })

    assert_response(:forbidden)
    @record.reload
    assert_equal("Sessão 1", @record.title)
    assert_nil(@record.supervision_record)
    assert_not(@record.reviewed?)
  end

  # --------------------------------------------------------------------------
  # Excluir
  # --------------------------------------------------------------------------

  test "terapeuta do atendimento exclui o prontuário" do
    sign_in_as(@therapist)

    delete(record_path)

    assert_response(:success)
    assert_not(MedicalRecord.exists?(@record.id))
  end

  test "supervisor não exclui o prontuário" do
    sign_in_as(@supervisor)

    delete(record_path)

    assert_response(:forbidden)
    assert(MedicalRecord.exists?(@record.id))
  end

  test "admin não exclui o prontuário" do
    sign_in_as(@admin)

    delete(record_path)

    assert_response(:forbidden)
    assert(MedicalRecord.exists?(@record.id))
  end

  # --------------------------------------------------------------------------
  # Consultar — a leitura continua aberta a quem já tinha acesso
  # --------------------------------------------------------------------------

  test "supervisor continua consultando o prontuário" do
    sign_in_as(@supervisor)
    get(record_path)
    assert_response(:success)

    sign_in_as(@supervisor)
    get(profile_medical_records_path(@patient))
    assert_response(:success)
  end

  test "admin continua consultando o prontuário" do
    sign_in_as(@admin)
    get(record_path)
    assert_response(:success)

    sign_in_as(@admin)
    get(profile_medical_records_path(@patient))
    assert_response(:success)
  end

  private

  def record_path
    profile_medical_record_path(@patient, @record)
  end

  def new_record_params(service = @free_service)
    {
      medical_record: {
        title: "Nova sessão",
        date: Date.current.to_s,
        evolution: "Evolução da nova sessão",
        service_id: service.id
      }
    }
  end

  def create_therapist(email, supervisor: nil, admin: false)
    profile = Profile.create!(
      name: email.split("@").first.capitalize,
      email: email,
      gender: :female,
      birth: 35.years.ago.to_date,
      role: :therapist,
      admin: admin,
      supervisor_id: supervisor&.id
    )

    User.create!(
      profile: profile,
      email: email,
      password: "Senha1234",
      password_confirmation: "Senha1234",
      confirmed_at: Time.current
    )

    profile
  end

  def create_service(therapist, start_time, end_time)
    Service.create!(
      patient: @patient,
      therapist: therapist,
      date: Date.current + 1.day,
      start_time: start_time,
      end_time: end_time,
      service_type: :clinical_psychology_tcc,
      status: :scheduled
    )
  end

  # A API não tem session store: o `sign_in` do Devise entra pelo
  # Warden.on_next_request e vale só para a requisição seguinte — por isso
  # cada requisição do teste tem a sua chamada.
  def sign_in_as(profile)
    sign_in(profile.user)
  end
end
