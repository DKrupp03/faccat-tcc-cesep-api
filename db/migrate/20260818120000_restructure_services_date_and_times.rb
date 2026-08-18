class RestructureServicesDateAndTimes < ActiveRecord::Migration[8.1]
  def up
    add_column(:services, :date, :date)
    add_column(:services, :start_time, :time)
    add_column(:services, :end_time, :time)

    execute(<<~SQL)
      UPDATE services SET
        date       = (datetime_start AT TIME ZONE 'America/Sao_Paulo')::date,
        start_time = (datetime_start AT TIME ZONE 'America/Sao_Paulo')::time,
        end_time   = (datetime_end   AT TIME ZONE 'America/Sao_Paulo')::time
    SQL

    change_column_null(:services, :date, false)
    change_column_null(:services, :start_time, false)
    change_column_null(:services, :end_time, false)

    add_index(:services, [ :date, :start_time ])

    remove_column(:services, :datetime_start)
    remove_column(:services, :datetime_end)
  end

  def down
    add_column(:services, :datetime_start, :datetime)
    add_column(:services, :datetime_end, :datetime)

    execute(<<~SQL)
      UPDATE services SET
        datetime_start = (date + start_time) AT TIME ZONE 'America/Sao_Paulo',
        datetime_end   = (date + end_time)   AT TIME ZONE 'America/Sao_Paulo'
    SQL

    change_column_null(:services, :datetime_start, false)
    change_column_null(:services, :datetime_end, false)

    remove_index(:services, [ :date, :start_time ])

    remove_column(:services, :date)
    remove_column(:services, :start_time)
    remove_column(:services, :end_time)
  end
end
