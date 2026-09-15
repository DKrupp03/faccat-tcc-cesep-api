class AddObservationsToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column(:payments, :observations, :text)
  end
end
