# rubocop:disable Lint/MissingCopEnableDirective, Metrics/BlockLength
Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  require 'sidekiq/web'
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'static_pages#home'

  devise_for :users, controllers: {
    registrations: 'registrations',
    omniauth_callbacks: 'omniauth_callbacks',
  }

  devise_scope :user do
    get '/login' => 'devise/sessions#new'
    get '/logout' => 'devise/sessions#destroy', method: :delete
    get 'sign_up' => 'devise/registrations#new'
    get 'signup' => 'devise/registrations#new'
    get '/confirm_email' => 'users#send_confirmation_link'
  end

  namespace :api do
    resources :lesson_completions, only: [:index]
    resources :points, only: %i[index show create]
  end

  get 'home' => 'static_pages#home'
  get 'about' => 'static_pages#about'
  get 'faq' => 'static_pages#faq'
  get 'contributing' => 'static_pages#contributing'
  get 'terms_of_use' => 'static_pages#terms_of_use'
  get 'styleguide' => 'static_pages#style_guide'
  get 'success_stories' => 'static_pages#success_stories'
  get 'sitemap' => 'sitemap#index', defaults: { format: 'xml' }

  # failure route if github information returns invalid
  get '/auth/failure' => 'omniauth_callbacks#failure'
  resources :users, only: %i[show update]

  namespace :users do
    resources :paths, only: :create
  end
  get 'dashboard' => 'users#show', as: :dashboard

  # Deprecated Route to Web Development 101 from external links
  get '/courses/web-development-101', to: redirect('/courses/foundations')
  get '/courses/web-development-101/%{id}', to: redirect('/courses/foundations/%{id}')

  get '/courses' => redirect('/paths')
  resources :courses, only: %i[index show] do
    resources :lessons, only: :show
  end

  namespace :lessons do
    resource :style_tests, only: %i[new create show]
  end

  resources :lessons, only: :show do
    resources :project_submissions, only: %i[index], controller: 'lessons/project_submissions'

    resources :lesson_completions, only: %i[create], as: 'completions'
    delete 'lesson_completions' => 'lesson_completions#destroy', as: 'lesson_completions'
  end

  resources :project_submissions do
    resources :flags, only: %i[create], controller: 'project_submissions/flags'
  end

  get '/paths/web-development-101', to: redirect('/paths/foundations')
  resources :paths, only: %i[index show]

  match '/404' => 'errors#not_found', via: %i[get post patch delete]

  # Explicitly redirect deprecated routes (301)
  get '/courses/curriculum' => redirect('/courses')
  get 'curriculum' => redirect('/courses')
  get 'scheduler' => redirect('/courses')
  get '/tracks', to: redirect('/paths')
  get '/tracks/:id', to: redirect('/paths/%{id}')
end
