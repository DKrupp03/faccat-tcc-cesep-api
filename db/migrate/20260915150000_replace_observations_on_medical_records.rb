class ReplaceObservationsOnMedicalRecords < ActiveRecord::Migration[8.1]
  # O texto de `observations` vira a evolução do atendimento, para não perder
  # o que já foi registrado; os registros documental e da supervisão são
  # opcionais e nascem vazios.
  def up
    add_column(:medical_records, :evolution, :text)
    add_column(:medical_records, :documentary_record, :text)
    add_column(:medical_records, :supervision_record, :text)

    execute("UPDATE medical_records SET evolution = observations")
    change_column_null(:medical_records, :evolution, false)

    remove_column(:medical_records, :observations)
  end

  def down
    add_column(:medical_records, :observations, :text)
    execute("UPDATE medical_records SET observations = evolution")
    change_column_null(:medical_records, :observations, false)

    remove_column(:medical_records, :evolution)
    remove_column(:medical_records, :documentary_record)
    remove_column(:medical_records, :supervision_record)
  end
end
