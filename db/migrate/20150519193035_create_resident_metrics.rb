class CreateResidentMetrics < ActiveRecord::Migration
  def up
    create_table :resident_metrics do |t|
      t.integer :property_id
      t.string :type
      t.string :status
      t.string :rental_type
      t.string :dimension
      t.integer :total

      t.timestamps
    end
    
    add_index "resident_metrics", ["property_id", "type"]
  end
  
  def down
    drop_table :resident_metrics
  end
end
