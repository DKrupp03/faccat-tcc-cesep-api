# Garante no banco as relações que os models tratam como um-para-um.
#
# - anamneses: o índice único era [therapist_id, patient_id], então trocar o
#   terapeuta do paciente permitia uma segunda anamnese, e o `has_one` de
#   Profile passava a devolver uma delas arbitrariamente.
# - payments / medical_records: a unicidade só existia como validação
#   `on: :create`, então uma edição trocando o service_id criava a duplicata.
class EnforceOneToOneAssociations < ActiveRecord::Migration[8.1]
  def up
    deduplicate!(:anamneses, :patient_id)
    deduplicate!(:payments, :service_id)
    deduplicate!(:medical_records, :service_id)

    remove_index(:anamneses, name: "index_anamnese_unique")
    add_index(:anamneses, :patient_id, unique: true, name: "index_anamneses_on_patient_id_unique")
    add_index(:payments, :service_id, unique: true, name: "index_payments_on_service_id_unique")
    add_index(:medical_records, :service_id, unique: true, name: "index_medical_records_on_service_id_unique")
  end

  def down
    remove_index(:medical_records, name: "index_medical_records_on_service_id_unique")
    remove_index(:payments, name: "index_payments_on_service_id_unique")
    remove_index(:anamneses, name: "index_anamneses_on_patient_id_unique")
    add_index(:anamneses, [ :therapist_id, :patient_id ], unique: true, name: "index_anamnese_unique")
  end

  private

  # Mantém o registro mais recente de cada grupo duplicado; os anteriores foram
  # substituídos na prática, já que o `has_one` só enxergava um deles.
  def deduplicate!(table, column)
    execute(<<~SQL)
      DELETE FROM #{table}
      WHERE id NOT IN (
        SELECT MAX(id) FROM #{table} GROUP BY #{column}
      )
    SQL
  end
end
