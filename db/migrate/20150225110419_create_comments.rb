class CreateComments < ActiveRecord::Migration
  def up
    create_table :comments do |t|
      t.integer :property_id
      t.string :resident_id
      t.string :type
      t.text :message
      t.string :ancestry
      
      t.integer :author_id
      t.string :author_type
      
      t.timestamps
    end
    
    add_index "comments", ["property_id"]
    add_index "comments", ["ancestry"]
  end
  
  def down
    drop_table :comments
  end
end
