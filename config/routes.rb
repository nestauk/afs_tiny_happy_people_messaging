Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  authenticate :admin do
    mount Blazer::Engine, at: "blazer"
    mount MissionControl::Jobs::Engine, at: "jobs"

    namespace :admin do
      resources :groups do
        resources :contents, except: %i[index destroy] do
          patch "archive", on: :member
        end
      end

      resources :users, only: %i[index show update] do
        get "dashboard", on: :collection
        resources :messages
      end

      resources :surveys do
        resources :questions, except: [:index] do
          patch "update_position", on: :member
        end
      end

      resources :admins, except: %i[show destroy]

      get "dashboard", to: "dashboards#show"
      get "dashboards/fetch_sign_up_data", to: "dashboards#fetch_sign_up_data"
      get "dashboards/fetch_click_through_data", to: "dashboards#fetch_click_through_data"

      patch "/admin/update_position/:id/", to: "contents#update_position", as: "update_position"
    end
  end

  devise_for :admins, skip: :registrations, controllers: {sessions: "sessions"}
  get "up" => "rails/health#show", :as => :rails_health_check

  # Defines the root path route ("/")
  root "users#new"

  post "messages/status" => "messages#status"
  post "messages/incoming" => "messages#incoming"
  get "/m/:token/", to: "messages#next", as: "track_link"

  get "/privacy_policy", to: "pages#privacy_policy"
  get "/terms", to: "pages#terms"
  get "/resources", to: "pages#resources"
  get "/about_us", to: "pages#about_us"

  resources :surveys, only: %i[edit update]

  resources :users, only: %i[new create edit update] do
    get "thank_you", on: :member
  end
end
