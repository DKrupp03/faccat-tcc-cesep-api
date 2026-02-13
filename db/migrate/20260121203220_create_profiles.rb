class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.string(:name, null: false)
      t.integer(:gender, null: false)
      t.date(:birth, null: false)
      t.string(:address)
      t.string(:occupation)
      t.integer(:marital_status)
      t.integer(:education_level)
      t.string(:phone)
      t.string(:cpf)
      t.string(:rg)
      t.string(:crp)
      t.jsonb(:parent, default: {})
      t.decimal(:default_value, precision: 10, scale: 2)
      t.text(:extra, default: nil)
      t.integer(:role, null: false)
      t.references(:therapist, type: :int, foreign_key: { to_table: :profiles })
      t.timestamps
    end
  end
end
