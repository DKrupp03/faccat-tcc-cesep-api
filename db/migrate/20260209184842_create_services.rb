class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.datetime(:datetime_start, null: false)
      t.datetime(:datetime_end, null: false)
      t.text(:observations, default: nil)
      t.integer(:service_type, null: false)
      t.integer(:service_status, null: false, default: 0)
      t.references(:patient, type: :int, null: false, foreign_key: { to_table: :profiles })
      t.references(:therapist, type: :int, null: false, foreign_key: { to_table: :profiles })
      t.timestamps
    end
  end
end
