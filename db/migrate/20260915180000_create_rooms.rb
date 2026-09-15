class CreateRooms < ActiveRecord::Migration[8.1]
  # Sala é opcional no atendimento. Ao excluí-la, os atendimentos apenas ficam
  # sem sala.
  def change
    create_table(:rooms) do |t|
      t.string(:name, null: false)
      t.timestamps
    end

    add_index(:rooms, :name, unique: true)

    add_reference(
      :services,
      :room,
      type: :int,
      null: true,
      foreign_key: { to_table: :rooms, on_delete: :nullify }
    )
  end
end
