class CreateAnamnese < ActiveRecord::Migration[8.1]
  def change
    create_table :anamneses do |t|
      t.integer(:anamnese_type, null: false)
      t.jsonb(:anamnese_data, null: false, default: {})
      t.text(:observations, default: nil)
      t.references(:patient, type: :int, null: false, foreign_key: { to_table: :users })
      t.references(:therapist, type: :int, null: false, foreign_key: { to_table: :users })
      t.timestamps
    end

    add_index(
      :anamneses,
      [:therapist_id, :patient_id],
      unique: true,
      name: "index_anamnese_unique"
    )
    add_index(:anamneses, :anamnese_type)
    add_index(:anamneses, :anamnese_data, using: :gin)
  end
end
