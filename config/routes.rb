Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'users/search', to: 'users#search', as: 'search_users'
  get 'teams/search', to: 'teams#search', as: 'search_teams'
  
  # super basic static homepage text hack
  root :controller => 'homepages', :action => "index", :as => :home

  resources :teams, :only => [:new, :create, :edit, :update, :index, :show, :destroy] do
    resources :people, :only => [:new, :create, :edit, :update, :destroy]
    resource :questions, :only => [:show, :create]
  end

  resources :races, :only => [:new, :create, :edit, :update, :index, :show, :destroy] do
    get :registrations
    get :export
    resources :requirements, :only => [:new, :create, :edit, :update, :destroy]
  end

  resources :tiers, :only => [:new, :create, :edit, :update, :destroy]

  # stripe
  resources :charges, :only => [:create] do
    post :refund
  end

  # mock payments for testing
  post 'mock_payment', to: 'mock_payments#create', as: :mock_payment

  # user accounts
  resources :users, :only => [:new, :create, :edit, :update, :index, :show, :destroy]
  resource :user_session, :only => [:new, :create, :destroy]
  resource :account, :controller => :users

  # password reset
  resources :password_resets, :only => [:new, :create, :edit, :update]

  # sidekiq
  mount Sidekiq::Web => '/sidekiq'

  #resources :foos, :only => [:index, :new, :create, :show, :edit, :update, :delete]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # Catch-all route for unmatched paths - returns 404 without raising exception
  # This prevents ActionController::RoutingError from being logged to Rollbar
  # Must be last route in the file
  match "*path", to: "errors#not_found", via: :all
end
