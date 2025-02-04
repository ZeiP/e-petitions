Rails.application.routes.draw do
  root to: 'pages#index'
  constraints Site.constraints_for_public do
    controller 'constituencies' do
      get '/constituencies', action: 'index', as: :constituencies
    end

    controller 'pages' do
      get '/',        action: 'index', as: :home
      get '/help',    action: 'help'
      get '/privacy', action: 'privacy'

      scope format: true do
        get '/browserconfig', action: 'browserconfig', constraints: { format: 'xml'  }
        get '/manifest',      action: 'manifest',      constraints: { format: 'json' }
      end
    end

    controller 'feedback' do
      scope '/feedback' do
        get  '/',       action: 'new',    as: :feedback
        post '/',       action: 'create', as: nil
        get  '/thanks', action: 'thanks', as: :thanks_feedback
      end
    end

    controller 'local_petitions' do
      scope '/petitions/local' do
        get '/',        action: 'index', as: :local_petitions
        get '/:id',     action: 'show',  as: :local_petition
        get '/:id/all', action: 'all',   as: :all_local_petition
      end
    end

    resources :petitions, only: %i[new show index] do
      collection do
        get  'check'
        get  'check_results'
        post 'new', action: 'create', as: nil
      end

      member do
        get 'count'
        get 'done'
        get 'gathering-support'
        get 'moderation-info'
      end

      resources :sponsors, only: %i[new create], shallow: true do
        collection do
          post 'new', action: 'confirm', as: :confirm
          get  'thank-you'
        end

        member do
          get 'verify'
          get 'sponsored', action: 'signed', as: :signed
        end
      end

      resources :signatures, only: %i[new create], shallow: true do
        collection do
          post 'new', action: 'confirm', as: :confirm
          get  'already-signed'
        end

        member do
          get 'verify'
          get 'unsubscribe'
          get 'signed'
        end
      end

      resources :trackers, only: %i[show], format: true, constraints: { id: /[-_0-9a-zA-Z]{20}/, format: 'gif' }
    end

    namespace :archived do
      resources :petitions, only: %i[index show]

      resources :signatures, only: [] do
        get 'unsubscribe', on: :member
      end
    end

    # REDIRECTS OLD PAGES
    get '/accessibility',         to: redirect('/help')
    get '/api/petitions',         to: redirect('/')
    get '/api/petitions/:id',     to: redirect('/')
    get '/crown-copyright',       to: redirect('https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm')
    get '/departments',           to: redirect('/')
    get '/departments/:id',       to: redirect('/')
    get '/how-it-works',          to: redirect('/help')
    get '/privacy-policy',        to: redirect('/privacy')
    get '/faq',                   to: redirect('/help')
    get '/terms-and-conditions',  to: redirect('/help')
  end

  constraints Site.constraints_for_moderation do
    get '/', to: redirect('/admin')

    namespace :admin do
      mount Delayed::Web::Engine, at: '/delayed'

      root to: 'admin#index'

      resource :parliament, only: %i[show update]
      resource :search, only: %i[show]

      resources :admin_users
      resources :profile, only: %i[edit update]
      resources :user_sessions, only: %i[create]

      resources :invalidations, except: %i[show] do
        post :cancel, :count, :start, on: :member
      end

      resource :moderation_delay, only: %i[new create], path: 'moderation-delay'

      resources :petitions, only: %i[show index] do
        post :resend, on: :member

        resources :emails, controller: 'petition_emails', except: %i[index show]
        resource  :lock, only: %i[show create update destroy]
        resource  :moderation, controller: 'moderation', only: %i[update]
        resource  :statistics, controller: 'petition_statistics', only: %i[update]
        resources :trending_ips, path: 'trending-ips', only: %i[index]
        resources :trending_domains, path: 'trending-domains', only: %i[index]

        scope only: %i[show update] do
          resource :debate_outcome, path: 'debate-outcome'
          resource :government_response, path: 'government-response', controller: 'government_response'
          resource :notes
          resource :details, controller: 'petition_details'
          resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
          resource :tags, controller: 'petition_tags'
          resource :take_down, path: 'take-down', controller: 'take_down'
          resource :close_early, path: 'close-early', controller: 'close_early'
        end

        resources :signatures, only: %i[index destroy] do
          post :validate, :invalidate, on: :member
          post :subscribe, :unsubscribe, on: :member

          collection do
            delete :destroy, action: :bulk_destroy
            post   :validate, action: :bulk_validate
            post   :invalidate, action: :bulk_invalidate
            post   :subscribe, action: :bulk_subscribe
            post   :unsubscribe, action: :bulk_unsubscribe
          end
        end
      end

      resources :domains, except: %i[show]

      resource :rate_limits, path: 'rate-limits', only: %i[edit update]
      resource :site, only: %i[edit update]
      resource :holidays, only: %i[edit update]
      resource :tasks, only: %i[create]

      resources :signatures, only: %i[index destroy] do
        post :validate, :invalidate, on: :member
        post :subscribe, :unsubscribe, on: :member

        collection do
          delete :destroy, action: :bulk_destroy
          post   :validate, action: :bulk_validate
          post   :invalidate, action: :bulk_invalidate
          post   :subscribe, action: :bulk_subscribe
          post   :unsubscribe, action: :bulk_unsubscribe
        end

        resource :logs, only: :show
      end

      resources :tags, except: %i[show]

      namespace :archived do
        root to: redirect('/admin/archived/petitions')

        resources :petitions, only: %i[show index] do
          resources :emails, controller: 'petition_emails', except: %i[index show]
          resource  :lock, only: %i[show create update destroy]

          scope only: %i[show update] do
            resource :debate_outcome, path: 'debate-outcome'
            resource :government_response, path: 'government-response', controller: 'government_response'
            resource :notes
            resource :details, controller: 'petition_details'
            resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
            resource :tags, controller: 'petition_tags'
          end
        end

        resources :signatures, only: %i[index destroy] do
          post :subscribe, :unsubscribe, on: :member

          collection do
            delete :destroy, action: :bulk_destroy
            post   :subscribe, action: :bulk_subscribe
            post   :unsubscribe, action: :bulk_unsubscribe
          end
        end
      end

      scope 'stats', controller: 'statistics' do
        get '/', action: 'index', as: :stats
        get '/moderation/:period', action: 'moderation', as: :moderation_stats, period: /week|month/
      end

      controller 'user_sessions' do
        get '/logout',   action: 'destroy'
        get '/login',    action: 'new'
        get '/continue', action: 'continue'
        get '/status',   action: 'status'
      end
    end
  end

  get 'ping', to: 'ping#ping'

  resources :saml, only: [:sso, :acs, :logout, :application_logout, :metadata] do
    collection do
      get :sso
      post :acs
      get :logout
      get :application_logout
      get :metadata
    end
  end

  if defined?(JasmineRails)
    mount JasmineRails::Engine, at: '/specs'
  end
end
