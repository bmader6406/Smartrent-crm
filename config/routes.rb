Rails.application.routes.draw do
  
  #mount Smartrent::Engine, :at => "/smartrent", :as => "smartrent"
  
  # shared
  def resident_resources
    resources :residents do
      member do 
        get :tickets
        get :roommates
        get :properties
        
        get :marketing_properties
        get :marketing_statuses
      end
      
      collection do
        get :search
      end
      
      resources :activities
    end
  end
  
  def report_resources
    resources :reports do
      collection do
        get :residents
        get :export_residents
        
        get :metrics
        get :export_metrics
      end
    end
  end
    
  # base
  resources :properties do
    member do
      get :info
    end
    
    resident_resources
    report_resources
    
    resources :roommates
    resources :tickets
    
    resources :units do
      member do
        get :residents
      end
    end
    
    resources :notifications
    
    resources :notices, :as => "campaigns", :controller => "campaigns" do
      member do
        get :preview
        post :abort
      end
      
      collection do
        get :preview_template
      end
    end
    
    resources :assets do
      member do
        post :select
      end
      
      collection  do
        post :import
      end
    end
  end
  
  resident_resources
  report_resources
  
  resources :users, :path => :accounts
  
  resource :profile
  resources :authentications
  resources :user_sessions
  resources :password_resets
  
  resources :downloads, only: [:show], :constraints => { :id => /[^\/]+/ }
  
  resource :twilio, :controller => :twilio do
    get :usage
    
    post :p2p_connect
    post :p2p_fallback
    post :p2p_status
    
    post :w2p_connect
    post :w2p_fallback
    post :w2p_status
  end
  
  namespace :nimda do
    # placeholder
  end
  
  # name route
  get 'login', :to => 'user_sessions#new', :as => :login
  get 'logout', :to => 'user_sessions#destroy', :as => :logout
  get 'forgot_password', :to => 'password_resets#new', :as => :forgot_password
  
  get '/auth/:provider/callback', :to => 'authentications#create'
  get '/auth/failure', :to => 'authentications#failure'
  
  root :to => 'dashboards#start'
  
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
  
end
