class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  belongs_to(:profile)
  
  devise(
    :database_authenticatable,
    :registerable,
    :recoverable,
    :rememberable,
    :validatable,
    :trackable,
    :confirmable,
    :jwt_authenticatable,
    jwt_revocation_strategy: self
  )
end
