class CreateServiceRecurrences < ActiveRecord::Migration[8.1]
  def change
    create_table(:service_recurrences) do |t|
      t.integer(:frequency, null: false)
      # "interval" é palavra reservada no Postgres, por isso o prefixo.
      t.integer(:repeat_interval, null: false, default: 1)
      t.date(:start_date, null: false)
      t.integer(:end_type, null: false, default: 0)
      t.date(:end_date)
      t.integer(:occurrences)
      t.integer(:weekday)
      t.integer(:month_day)
      t.timestamps
    end

    add_reference(
      :services,
      :recurrence,
      type: :int,
      null: true,
      foreign_key: { to_table: :service_recurrences }
    )
  end
end
