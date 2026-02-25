class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  PASSWORD_REGEX = /\A(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z]).{8,100}\z/

  belongs_to(:profile)

  validates(:profile_id, presence: true)
  validates(:email, presence: true)
  validates(:encrypted_password, presence: true)
  validates(:jti, presence: true)

  validates(
    :password,
    format: {
      with: PASSWORD_REGEX,
      message: "A senha deve conter ao menos 1 letra maiúscula, 1 minúscula e 1 número (8-100 caracteres)"
    },
    if: :password_required?
  )

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

  def show
    user = self.to_o
    user.store(:profile, self.profile)
    user
  end
end
