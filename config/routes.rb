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
        get "preview", on: :member
        get "preview_thank_you", on: :member
        resources :survey_sections, except: %i[index show] do
          resources :questions, except: [:index] do
            patch "update_position", on: :member
          end
        end
      end

      resources :admins, except: %i[show destroy]

      patch "/admin/update_position/:id/", to: "contents#update_position", as: "update_position"
    end
  end

  devise_for :admins, skip: :registrations, controllers: {sessions: "sessions"}
  get "up" => "rails/health#show", :as => :rails_health_check

  # Defines the root path route ("/")
  root "users#new"

  post "messages/twilio_status" => "messages#twilio_status"
  post "messages/twilio_incoming" => "messages#twilio_incoming"
  post "messages/aws_status" => "messages#aws_status"
  post "messages/aws_incoming" => "messages#aws_incoming"
  get "/m/:token/", to: "messages#next", as: "track_link"

  post "cookie_consent" => "cookie_consents#create"

  get "/privacy_policy", to: "pages#privacy_policy"
  get "/terms", to: "pages#terms"
  get "/resources", to: "pages#resources"
  get "/about_us", to: "pages#about_us"
  get "/cookie_policy", to: "pages#cookie_policy"
  get "/accessibility", to: "pages#accessibility"

  resources :surveys, only: %i[edit update] do
    get "thank_you", on: :member
  end

  resources :users, only: %i[new create edit update] do
    get "thank_you", on: :member
  end
end
