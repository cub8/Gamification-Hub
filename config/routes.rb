# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  resources :join, param: :code, only: %i[show new] do
    collection do
      post :create
      # Step 1 submits here. Declared on the collection so it is matched before
      # /join/:code, which would otherwise swallow "lookup" as a code.
      get :lookup
    end
  end
  resources :story_groups do
    resource :ranking, only: :show, controller: :ranking do
      post :change_status
    end
    resources :items, except: :show do
      # Like ranks and badges: the delete confirmation carries a consequence
      # sentence and the number of copies students already own, so it needs the
      # record. A GET route rather than a JS-built dialog, so it also works as a
      # page when the turbo frame is not there.
      get :confirm_destroy, on: :member
    end
    resources :activity_group_templates
    resources :activity_groups, except: %i[show new] do
      post :create_bulk, on: :collection
      resource :students_activity_group_categories, only: %i[edit update]
    end
    resources :ranks, except: :show do
      # Same as invites: the delete confirmation is a dialog carrying a
      # consequence sentence and the list of items that require the rank, which
      # a browser confirm cannot hold, so it needs a URL to render into.
      get :confirm_destroy, on: :member
    end
    resources :badges, except: :show do
      # Same as ranks: the delete confirmation carries a consequence sentence
      # and, when items unlock on the badge, the list of what stops being
      # buyable — neither of which fits in a browser confirm.
      get :confirm_destroy, on: :member
    end
    resources :teachers, only: %i[new index create destroy]
    resources :students do
      member do
        post :update_lives
      end
      resource :currency_adjustment, only: %i[new create]
      resources :students_badges, path: :badges, as: :badges, only: %i[new create destroy]
      resources :currency_transactions, only: :index
      resources :students_items, path: :items, only: %i[index show]
    end
    # No :show — the shop card carries everything a detail page would, at every
    # width, so nothing links to one.
    resources :shop, only: :index do
      member do
        # The buy confirmation is a dialog holding the price, the discount and
        # what will be left over, none of which fits in a browser confirm. A GET
        # route like every other confirmation here, so it renders as a page when
        # the turbo frame is not there — and so the server re-checks the offer
        # before quoting a price.
        get :confirm_buy
        post :buy
      end
    end
    resources :students_profile, path: :profile, as: :profile, only: %i[index]
    resources :story_group_invites, path: :invites, as: :invites do
      # The delete confirmation is a dialog with a consequence sentence in it,
      # not a browser confirm, so it needs a URL of its own to render into.
      get :confirm_destroy, on: :member
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

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root 'root#index'
end
