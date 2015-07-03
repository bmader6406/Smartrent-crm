class CreateRegions < ActiveRecord::Migration
  def up
    create_table :regions do |t|
      t.string :name

      t.timestamps null: false
    end
    
  end
  
  def down
    drop_table :regions
  end
end
