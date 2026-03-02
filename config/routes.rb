Rails.application.routes.draw do
  defaults format: :json do
    devise_for(:users,
      path: "",
      path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup"
      },
      controllers: {
        sessions: "sessions",
        registrations: "registrations",
        passwords: "passwords"
      }
    )
  end

  resources(:profiles, only: [:index, :show, :create, :update])

  resources(:services, only: [:index, :show, :create, :update, :destroy])
end
