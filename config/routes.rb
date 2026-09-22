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
    # Deleting a group takes its students, teachers, shop, ranking and every
    # ledger row with it (DECISIONS.md:28). The confirmation carries those
    # counts and a type-the-name gate, neither of which fits in a browser
    # confirm, so it needs a URL to render into.
    get :confirm_destroy, on: :member

    # The creation wizard's last step. Nothing exists yet at this point, so it
    # is a collection route reading `pack` and `classes` off the query and
    # answering with the rows for the frame inside the form.
    get :preset_preview, on: :collection

    # The wizard's success screen. Its own page rather than a flash on the
    # group: it lists what was created and what to do next, and a teacher who
    # reloads should see it again rather than a bare redirect.
    get :created, on: :member

    resource :ranking, only: %i[show update], controller: :ranking do
      # Every change to what students see is confirmed first: showing the board
      # exposes places, hiding it takes them away, and the mode decides how much
      # of the list they get (DECISIONS.md:36, widened here to all four
      # transitions). GET routes rendering into the dialog frame, like every
      # other confirmation in this file — a browser confirm cannot hold the
      # sentence that explains what each one does to the student's view.
      get :confirm_visibility
      get :confirm_mode
    end
    resources :items, except: :show do
      # Like ranks and badges: the delete confirmation carries a consequence
      # sentence and the number of copies students already own, so it needs the
      # record. A GET route rather than a JS-built dialog, so it also works as a
      # page when the turbo frame is not there.
      get :confirm_destroy, on: :member
    end
    # "Arkusze ocen". Templates have no index of their own — they are listed
    # inside activity_groups#index, one panel each — and no show: the template
    # is only ever edited.
    resources :activity_group_templates, except: %i[index show] do
      get :confirm_destroy, on: :member
    end
    resources :activity_groups, except: :show do
      # `new` is the "Utwórz arkusz" dialog, which needs the template it is
      # stamping from. Creating one sheet and creating several is one form
      # posting to #create with a count, so there is no separate bulk route.
      get :confirm_destroy, on: :member
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
        # Removing a student destroys their badges, their purchases and their
        # whole currency history. The confirmation carries those counts, which
        # a browser confirm cannot hold, so it needs a URL to render into.
        get :confirm_destroy
      end
      resource :currency_adjustment, only: %i[new create]
      resources :students_badges, path: :badges, as: :badges, only: %i[new create destroy] do
        # Same as everywhere else: the revoke confirmation names the discount
        # the student loses and what stops being buyable.
        get :confirm_destroy, on: :member
      end
      resources :currency_transactions, only: :index
      # No :show — the card carries the price paid, the discount and the date,
      # so nothing links to a detail page. Same reasoning as the shop.
      resources :students_items, path: :items, only: %i[index]
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

    # "Ustawienia w grupie": a student's own settings HERE — their nickname,
    # what the teacher can see, and the way out. Singular, because you have at
    # most one membership per group and never address somebody else's.
    resource :membership, only: %i[edit update destroy], controller: :story_group_memberships do
      # Leaving destroys the membership, and with it the badges, the purchases
      # and the whole currency history. The confirmation carries those counts,
      # which a browser confirm cannot hold, so it needs a URL to render into.
      get :confirm_leave

      # The same field as #edit, as a dialog. The ranking screen is where a
      # student is most likely to want their nickname changed — it is the only
      # place it is shown to anyone else — so "Zmień" there opens this rather
      # than sending them to the settings page and back.
      get :nickname
    end
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
