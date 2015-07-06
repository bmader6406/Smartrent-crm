class CreateCalls < ActiveRecord::Migration
  def up
    create_table :calls do |t|
      t.integer :comment_id
      t.string :from
      t.string :to
      t.integer :recording_duration, :default => 0
      t.string :recording_url
      
      t.timestamps
    end
    
    add_index "calls", ["comment_id"]
  end
  
  def down
    drop_table :calls
  end
end
