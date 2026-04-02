class SessionsController < Devise::SessionsController
  respond_to(:json)

  private

  def respond_with(resource, _opts = {})
    render_json_success({ user: { id: resource.id, email: resource.email } })
  end

  def respond_to_on_destroy(resource)
    if resource
      render_json_success()
    else
      render_json_errors(
        I18n.t("activerecord.errors.messages.no_active_session"),
        status: :unauthorized
      )
    end
  end
end
