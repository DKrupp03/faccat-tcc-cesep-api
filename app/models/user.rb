class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  PASSWORD_REGEX = /\A(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z]).{8,100}\z/

  belongs_to(:profile)

  validates(:email, presence: true)

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
    user = self.attributes
    user.store(:profile, self.profile)
    user
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end
end
