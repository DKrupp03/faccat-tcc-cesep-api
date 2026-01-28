class Anamnese < ApplicationRecord
  belongs_to(:user, class_name: 'User', foreign_key: :patient_id)
end
