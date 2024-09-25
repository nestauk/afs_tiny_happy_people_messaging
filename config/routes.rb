Rails.application.routes.draw do
  devise_for :admins, skip: :registrations
  authenticate :admin do
    mount Blazer::Engine, at: 'admin'
    mount FieldTest::Engine, at: 'field_test'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', :as => :rails_health_check

  # Defines the root path route ("/")
  root 'interests#new'

  post 'messages/status' => 'messages#status'
  post 'messages/incoming' => 'messages#incoming'
  get 'messages/next' => 'messages#next'

  resources :users, only: %i[new create index show] do
    get 'dashboard', on: :collection
    resources :messages
  end

  get '/m/:token/', to: 'messages#next', as: 'track_link'

  resources :groups do
    resources :contents, except: %i[index]
  end

  resources :admins, except: %i[show destroy]

  patch '/update_position/:id/', to: 'contents#update_position', as: 'update_position'

  resources :interests, only: %i[new create]

  get 'examples' => 'examples#index'
end
