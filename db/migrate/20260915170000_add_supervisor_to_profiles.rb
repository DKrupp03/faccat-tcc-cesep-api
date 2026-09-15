class AddSupervisorToProfiles < ActiveRecord::Migration[8.1]
  # Supervisor é outro terapeuta (opcional). Ao excluí-lo, os subordinados
  # apenas ficam sem supervisor.
  def change
    add_column(:profiles, :supervisor_id, :integer)
    add_index(:profiles, :supervisor_id)
    add_foreign_key(:profiles, :profiles, column: :supervisor_id, on_delete: :nullify)
  end
end
