# GET /me — reidratação da sessão: devolve o usuário autenticado a partir do
# cookie JWT (o token não fica mais acessível ao JavaScript no front).
#
# Controller comum (não-Devise) para não depender do devise.mapping das rotas
# do Devise; authenticate_user! funciona em qualquer controller via warden.
class CurrentUserController < ApplicationController
  before_action(:authenticate_user!)

  def show
    render_json_success({
      user: {
        id: current_user.id,
        email: current_user.email,
        profile_id: current_user.profile_id
      }
    })
  end
end
