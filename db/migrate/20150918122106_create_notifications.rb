class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :property_id
      t.integer :resident_id, :limit => 8
      
      # user
      t.integer :owner_id
      
      t.string :state, :default => "pending"
      t.string :subject
      t.text :message

      # user
      t.integer :last_actor_id
      
      # for later use
      t.integer :comment_id
      
      t.datetime :deleted_at

      t.timestamps null: false
    end
    
    add_index "notifications", ["property_id", "resident_id"]
    add_index "notifications", ["property_id", "state", "created_at"]
    
    add_index "notifications", ["comment_id"]
    
    create_table :notification_histories do |t|
      t.integer :notification_id
      t.string :state
      
      # user
      t.integer :actor_id
      
      t.timestamps null: false
    end
    
    add_index "notification_histories", ["notification_id", "state"]    
  end
end
