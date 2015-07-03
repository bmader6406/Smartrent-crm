class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string   :email
      t.string   :last_name
      t.string   :first_name
      t.string   :time_zone
      t.string   :address1
      t.string   :address2
      t.string   :city
      t.string   :state
      t.string   :zip
      t.string   :country
      t.string   :phone
      t.string   :referer
      t.string   :avatar_url
      t.boolean  :active,            :default => true
      
      t.string   :crypted_password
      t.string   :password_salt
      t.string   :persistence_token
      t.string   :perishable_token
      t.integer  :login_count,       :default => 0,       :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string   :last_login_ip
      t.string   :current_login_ip
      
      t.timestamps null: false
    end
    
    add_index "users", ["email"], :name => "index_users_on_email"
    add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
    add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  end
  
  def down
    drop_table :users
  end
end
