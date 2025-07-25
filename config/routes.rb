Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  authenticate :admin do
    mount Blazer::Engine, at: "admin"
    mount MissionControl::Jobs::Engine, at: "jobs"

    resources :groups do
      resources :contents, except: %i[index destroy] do
        patch "archive", on: :member
      end
    end

    resources :admins, except: %i[show destroy]

    resources :content_adjustments, only: %i[index show edit update] do
      get "automated", on: :collection
      get "incomplete", on: :collection
    end
  end

  devise_for :admins, skip: :registrations, controllers: {sessions: "devise/passwordless/sessions"}
  get "up" => "rails/health#show", :as => :rails_health_check

  # Defines the root path route ("/")
  root "users#new"

  post "messages/status" => "messages#status"
  post "messages/incoming" => "messages#incoming"
  get "/m/:token/", to: "messages#next", as: "track_link"

  get "/privacy_policy", to: "pages#privacy_policy"
  get "/terms", to: "pages#terms"
  get "/resources", to: "pages#resources"
  get "/diary_study", to: "pages#diary_study"
  get "/about_us", to: "pages#about_us"

  resources :users, only: %i[new create index show edit update] do
    get "dashboard", on: :collection
    get "thank_you", on: :collection
    get "assess", on: :member
    resources :messages
  end

  get "dashboard", to: "dashboards#show"
  get "dashboards/fetch_sign_up_data", to: "dashboards#fetch_sign_up_data"
  get "dashboards/fetch_click_through_data", to: "dashboards#fetch_click_through_data"

  patch "/update_position/:id/", to: "contents#update_position", as: "update_position"
end
