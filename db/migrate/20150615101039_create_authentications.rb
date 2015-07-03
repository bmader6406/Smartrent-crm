class CreateAuthentications < ActiveRecord::Migration
  def up
    create_table :authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid
      t.string :name
      t.string :oauth_token
      t.string :oauth_secret
      t.datetime :oauth_expires_at

      t.timestamps null: false
    end
    
    add_index "authentications", ["user_id"]
  end
  
  def down
    drop_table :authentications
  end
end
