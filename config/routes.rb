# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  resources :join, param: :code, only: %i[show new] do
    collection do
      post :create
      get :lookup
    end
  end
  resources :story_groups do
    get :confirm_destroy, on: :member
    get :preset_preview, on: :collection
    get :created, on: :member

    resource :ranking, only: %i[show update], controller: :ranking do
      get :confirm_visibility
      get :confirm_mode
    end

    resources :items, except: :show do
      get :confirm_destroy, on: :member
    end

    resources :activity_group_templates, except: %i[index show] do
      get :confirm_destroy, on: :member
    end
    resources :activity_groups, except: :show do
      get :confirm_destroy, on: :member
      resource :students_activity_group_categories, only: %i[edit update]
    end
    resources :ranks, except: :show do
      get :confirm_destroy, on: :member
    end
    resources :badges, except: :show do
      get :confirm_destroy, on: :member
    end
    resources :teachers, only: %i[new index create destroy] do
      get :confirm_destroy, on: :member
    end
    resources :students, except: %i[new create] do
      member do
        post :update_lives
        get :confirm_destroy
      end

      resource :currency_adjustment, only: %i[new create]
      resources :students_badges, path: :badges, as: :badges, only: %i[new create destroy] do
        get :confirm_destroy, on: :member
      end

      resources :currency_transactions, only: :index
      resources :students_items, path: :items, only: %i[index]
    end

    resources :shop, only: :index do
      member do
        get :confirm_buy
        post :buy
      end
    end

    resource :membership, only: %i[edit update destroy], controller: :story_group_memberships do
      get :confirm_leave
      get :nickname
    end

    resources :story_group_invites, path: :invites, as: :invites do
      get :confirm_destroy, on: :member
      # The lightweight sibling of the index: today's active code(s)
      # projected large, no id in the URL because it's never about one
      # particular invite.
      get :quick, on: :collection
    end
  end

  resources :notifications, only: %i[index] do
    post :mark_as_read, on: :collection
  end

  namespace 'auth' do
    get '/:provider/callback', to: 'usos#create', as: :callback
    resource :passwordless, only: %i[new create], controller: 'passwordless'
    get 'passwordless/verify', to: 'passwordless#verify', as: :passwordless_verify
    get 'passwordless/inbox', to: 'passwordless#inbox', as: :passwordless_inbox
  end

  get '/login', to: 'sessions#new', as: :login
  delete '/logout', to: 'sessions#destroy', as: :logout
  get '/home', to: 'home#index', as: :home

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'root#index'
end
