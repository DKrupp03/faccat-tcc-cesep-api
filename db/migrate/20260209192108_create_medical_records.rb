class CreateMedicalRecords < ActiveRecord::Migration[8.1]
  def change
    create_table(:medical_records) do |t|
      t.string(:title, null: false)
      t.date(:date, null: false)
      t.text(:observations, null: false)
      t.references(:service, type: :int, null: false, foreign_key: { to_table: :services })
      t.timestamps
    end
  end
end
