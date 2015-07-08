Rails.application.routes.draw do
  mount Smartrent::Engine, :at => "/smartrent", :as => "smartrent"
  
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
      
      resources :reports, :controller => "campaign_reports"
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
  
  resources :downloads, only: [:show], :constraints => { :id => /[^\/]+/ }
  
  # email system
  resources :unsubscribes do
    member do
      post :subscribe
      post :confirm
    end
  end
  
  get '/nlt/:nlt_id' => 'public#nlt', :as => :nlt
  get '/nlt2/:cid' => 'public#nlt2', :as => :nlt2
  get '/t/:token' => 'public#tracker', :as => :t
  get '/pixel' => 'public#pixel', :as => :pixel
  
  resources :receivers do
    collection do
      get :ses_sns
      post :ses_sns
    end
  end
  
  ## user model
  resources :users, :path => :accounts
  
  resource :profile
  resources :authentications
  resources :user_sessions
  resources :password_resets
  
  
  resource :twilio, :controller => :twilio do
    get :usage
    
    post :p2p_connect
    post :p2p_fallback
    post :p2p_status
    
    post :w2p_connect
    post :w2p_fallback
    post :w2p_status
  end
  
  # admin
  namespace :nimda do
    resources :templates do
      member do
        get :preview
      end
      
    end
  end
  
  get 'login', :to => 'user_sessions#new', :as => :login
  get 'logout', :to => 'user_sessions#destroy', :as => :logout
  get 'forgot_password', :to => 'password_resets#new', :as => :forgot_password
  
  get '/auth/:provider/callback', :to => 'authentications#create'
  get '/auth/failure', :to => 'authentications#failure'
  
  root :to => 'dashboards#start'
end
