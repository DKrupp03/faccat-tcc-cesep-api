class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  PASSWORD_REGEX = /\A(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z]).{8,100}\z/

  belongs_to(:profile)

  validates(:email, presence: true)

  validates(
    :password,
    format: {
      with: PASSWORD_REGEX,
      message: I18n.t("activerecord.errors.models.user.attributes.password.invalid")
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

  def self.revoke_jwt(payload, user)
    user&.update_column(:jti, SecureRandom.uuid)
  end

  # Perfil inativo não entra — antes desativar só escondia o terapeuta dos
  # selects. Vale para a sessão já aberta: o hook after_set_user do Devise checa
  # isto a cada requisição, então o JWT em circulação para de ser aceito na hora.
  def active_for_authentication?
    super && profile&.active?
  end

  def inactive_message
    profile&.active? ? super : :inactive_profile
  end

  def show
    user = self.attributes
    user.store(:profile, self.profile)
    user
  end
end
