class CreateEmails < ActiveRecord::Migration
  def up
    create_table :emails do |t|
      t.integer :comment_id
      t.string :subject
      t.string :from
      t.string :to
      t.text :message
      t.string :token
      t.string :message_id

      t.timestamps
    end
    
    change_column "emails", "id", "bigint"
    add_index "emails", ["comment_id"]
    add_index "emails", ["token"]
  end
  
  def down
    drop_table :emails
  end
end
