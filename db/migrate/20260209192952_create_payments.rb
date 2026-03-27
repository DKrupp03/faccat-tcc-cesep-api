class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table(:payments) do |t|
      t.decimal(:value, precision: 10, scale: 2, null: false)
      t.date(:expiration_date, null: false)
      t.date(:payment_date)
      t.integer(:payment_method)
      t.references(:service, type: :int, null: false, foreign_key: { to_table: :services })
      t.timestamps
    end
  end
end
