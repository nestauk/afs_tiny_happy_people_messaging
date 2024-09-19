Rails.application.routes.draw do
  devise_for :admins
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Defines the root path route ("/")
  root "interests#new"

  post "messages/status" => "messages#status"
  post "messages/incoming" => "messages#incoming"

  resources :users, only: %i[new create index show] do
    get "dashboard", on: :collection
    resources :messages do
      get :next, on: :collection
    end
  end

  resources :groups do
    resources :contents, except: %i[index]
  end

  patch "/update_position/:id/", to: "contents#update_position", as: "update_position"

  resources :interests, only: %i[new create]

  get "examples" => "examples#index"
end
