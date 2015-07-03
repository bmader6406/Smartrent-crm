class CreateUnits < ActiveRecord::Migration
  def up
    create_table :units do |t|
      t.integer :property_id
      t.integer :bed
      t.integer :bath
      t.float :sq_ft
      t.string :status
      t.text :description

      t.timestamps
    end
    
    change_column "units", "id", "bigint"
    add_index "units", ["property_id"]
  end
  
  def down
    drop_table :units
  end
end
