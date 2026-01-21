Rails.application.routes.draw do
  devise_for :users

  # Authenticated routes
  authenticate :user do
    root "dashboard#index", as: :authenticated_root

    get "dashboard", to: "dashboard#index"

    resources :organizations do
      resources :memberships, only: [:create, :update, :destroy]
    end

    resources :projects do
      resources :scans, only: [:new, :create]
      resources :reports, only: [:new, :create]
      resources :policies do
        member do
          patch :toggle
        end
      end
      member do
        post :generate_summary_report, to: "reports#generate_summary_report"
        post :generate_detailed_report, to: "reports#generate_detailed_report"
        post :generate_executive_report, to: "reports#generate_executive_report"
        post :generate_trend_report, to: "reports#generate_trend_report"
      end
    end

    resources :reports, only: [:index, :show, :destroy] do
      member do
        get :download
      end
    end

    resources :scans, only: [:index, :show] do
      member do
        get :status
        get :download_sbom
        post :rescan
      end
    end

    resources :vulnerabilities, only: [:index, :show]

    resources :notifications, only: [:index, :show] do
      member do
        patch :mark_as_read
      end
      collection do
        post :mark_all_as_read
      end
    end

    resource :notification_preferences, only: [:edit, :update] do
      post :test_webhook
    end

    resources :activity_logs, only: [:index]

    # API routes for SBOM Engine integration
    namespace :api do
      namespace :v1 do
        # SBOM Engine status and direct operations
        get "sbom_engine/status", to: "sbom_engine#status"
        post "sbom_engine/inspect", to: "sbom_engine#inspect"
        get "sbom_engine/progress/:task_id", to: "sbom_engine#progress"
        get "sbom_engine/result/:task_id", to: "sbom_engine#result"

        # Vulnerability queries via SBOM Engine
        get "vulnerabilities/cve", to: "vulnerabilities#cve"
        get "vulnerabilities/cwe", to: "vulnerabilities#cwe"
        get "vulnerabilities/ghsa", to: "vulnerabilities#ghsa"
        get "vulnerabilities/kev", to: "vulnerabilities#kev"
        get "vulnerabilities/osv", to: "vulnerabilities#osv"
        get "vulnerabilities/search", to: "vulnerabilities#search"

        # License information
        resources :licenses, only: [:index]
      end
    end
  end

  # Unauthenticated root
  devise_scope :user do
    root to: "devise/sessions#new"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
