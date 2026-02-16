class SessionsController < Devise::SessionsController
  respond_to(:json)

  private

  def respond_with(resource, _opts = {})
    render(json: {
      user: {
        id: resource.id,
        email: resource.email
      }
    }, status: :ok)
  end

  def respond_to_on_destroy(resource)
    if resource
      render(json: {
        message: "Deslogado com sucesso!",
      }, status: :ok)
    else
      render(json: {
        message: "Não foi possível encontrar uma sessão ativa!",
      }, status: :unauthorized)
    end
  end
end
