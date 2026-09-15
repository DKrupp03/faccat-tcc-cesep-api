class AddFreeToPayments < ActiveRecord::Migration[8.1]
  # Pagamento gratuito não tem cobrança: valor e vencimento ficam nulos, então
  # deixam de ser NOT NULL no banco (a obrigatoriedade fica no model).
  def change
    add_column(:payments, :free, :boolean, default: false, null: false)
    change_column_null(:payments, :value, true)
    change_column_null(:payments, :expiration_date, true)
  end
end
