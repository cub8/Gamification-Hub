# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  resources :story_groups do
    resources :items, except: :show
    resources :activity_group_templates
    resources :activity_groups, except: :new do
      post :create_bulk, on: :collection
      patch :save_completions, on: :member
    end
    resources :ranks
    resources :badges
    resources :teachers, only: %i[new index create destroy]
    resources :students, only: %i[new index create destroy]
  end

  namespace 'auth' do
    get '/:provider/callback', to: 'usos#create', as: :callback
    resource :passwordless, only: %i[new create], controller: 'passwordless'
    get 'passwordless/verify', to: 'passwordless#verify', as: :passwordless_verify
  end

  get '/login', to: 'sessions#new', as: :login
  delete '/logout', to: 'sessions#destroy', as: :logout
  get '/home', to: 'home#index', as: :home

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root 'root#index'
end
