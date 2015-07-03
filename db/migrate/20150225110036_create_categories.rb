class CreateCategories < ActiveRecord::Migration
  def up
    create_table :categories do |t|
      t.string :name
      t.string :abbr
      t.integer :position, :default => 0
      t.boolean :active, :default => true
      t.datetime :deleted_at
      
      t.timestamps
    end

  end
  
  def down
    drop_table :categories
  end
end
