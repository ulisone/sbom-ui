Rails.application.routes.draw do
  devise_for :users

  # Authenticated routes
  authenticate :user do
    root "dashboard#index", as: :authenticated_root

    get "dashboard", to: "dashboard#index"

    resources :projects do
      resources :scans, only: [:new, :create]
    end

    resources :scans, only: [:index, :show] do
      member do
        get :status
        get :download_sbom
        post :rescan
      end
    end

    resources :vulnerabilities, only: [:index, :show]
  end

  # Unauthenticated root
  devise_scope :user do
    root to: "devise/sessions#new"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
