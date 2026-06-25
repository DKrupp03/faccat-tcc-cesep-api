Rails.application.routes.draw do
  # Health check usado pelo kamal-proxy / load balancer (retorna 200 quando o app está saudável).
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

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

  resources(:profiles, only: [ :index, :show, :create, :update, :destroy ]) do
    resources(:anamneses, only: [ :show, :create, :update ])
    resources(:medical_records, only: [ :index, :show, :create, :update, :destroy ])
  end

  resources(:services, only: [ :index, :show, :create, :update, :destroy ])

  resources(:payments, only: [ :index, :show, :create, :update, :destroy ]) do
    collection do
      get :status_chart
      get :monthly_chart
    end
  end
end
