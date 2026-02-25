class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  belongs_to(:profile)

  validates(:profile_id, presence: true)
  validates(:email, presence: true)
  validates(:encrypted_password, presence: true)
  validates(:jti, presence: true)

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
