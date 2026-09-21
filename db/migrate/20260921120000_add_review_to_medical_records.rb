class AddReviewToMedicalRecords < ActiveRecord::Migration[8.1]
  # O "visto" da supervisão: além da marca, guarda quem viu e quando. O visto
  # nasce falso; ao excluir o supervisor, o prontuário só perde a referência.
  def change
    add_column(:medical_records, :reviewed, :boolean, null: false, default: false)
    add_column(:medical_records, :reviewer_id, :integer)
    add_column(:medical_records, :reviewed_at, :datetime)

    add_index(:medical_records, :reviewer_id)
    add_foreign_key(:medical_records, :profiles, column: :reviewer_id, on_delete: :nullify)
  end
end
