class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string(:name, null: false)
      t.integer(:gender, null: false)
      t.string(:phone, null: false)
      t.string(:email, null: false)
      t.date(:birth, null: false)
      t.string(:cpf, null: false)
      t.string(:rg)
      t.integer(:user_type, null: false)
      t.string(:crp)
      t.text(:extra, default: nil)
      t.timestamps
    end
  end
end
