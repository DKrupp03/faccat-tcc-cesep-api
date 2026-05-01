class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table(:profiles) do |t|
      t.string(:name, null: false)
      t.string(:email, null: false)
      t.integer(:gender, null: false)
      t.date(:birth, null: false)
      t.string(:address)
      t.string(:occupation) # only patients
      t.integer(:marital_status) # only patients
      t.integer(:education_level) # only patients
      t.string(:phone)
      t.string(:cpf)
      t.string(:rg)
      t.string(:crp) # only therapists
      t.jsonb(:parent, default: {}) # only patients
      t.decimal(:default_value, precision: 10, scale: 2) # only patients
      t.text(:extra, default: nil) # only patients
      t.integer(:role, null: false)
      t.boolean(:admin, default: false, null: false)
      t.boolean(:active, default: true)
      t.references(:therapist, type: :int, foreign_key: { to_table: :profiles }) # only patients
      t.timestamps
    end
  end
end
