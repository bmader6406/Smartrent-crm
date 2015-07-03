class CreateAssets < ActiveRecord::Migration
  def up
    create_table :assets do |t|
      t.integer :comment_id
      t.string   :type
      t.string   :file_file_name
      t.string   :file_content_type
      t.integer  :file_file_size
      t.datetime :file_updated_at
      t.string   :dimensions
      
      t.timestamps
    end
    
    change_column "assets", "id", "bigint"
    add_index "assets", ["comment_id"]
  end
  
  def down
    drop_table :assets
  end
end
