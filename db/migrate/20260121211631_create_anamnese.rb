class CreateAnamnese < ActiveRecord::Migration[8.1]
  def change
    create_table :anamneses do |t|
      t.text(:observations)
      t.string(:emergency_contact)
      t.text(:initial_complaint)
      t.text(:symptom_time)
      t.text(:disease_history)
      t.text(:medications)
      t.boolean(:physical_activity, default: false)
      t.boolean(:smoking, default: false)
      t.boolean(:healthy_eating, default: false)
      t.boolean(:alcoholic, default: false)
      t.references(:patient, type: :int, index: true, foreign_key: { to_table: :users })
      t.timestamps
    end
  end
end
