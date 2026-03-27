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

  resources(:profiles, only: [:index, :show, :create, :update]) do
    resources(:anamneses, only: [:show, :create, :update])
    resources(:medical_records, only: [:index, :show, :create, :update, :destroy])
  end

  resources(:services, only: [:index, :show, :create, :update, :destroy])

  resources(:payments, only: [:index, :show, :create, :update, :destroy])
end
