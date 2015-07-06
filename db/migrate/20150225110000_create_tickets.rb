class CreateTickets < ActiveRecord::Migration
  def up
    create_table :tickets do |t|
      t.integer :property_id
      t.integer :resident_id, :limit => 8
      
      t.string :title
      t.text :description
      t.string :status
      t.string :urgency
      
      t.integer :category_id
      t.integer :assigner_id
      t.integer :assignee_id
      
      t.boolean :can_enter, :default => false
      t.string :entry_instruction
      
      t.string :additional_emails
      t.string :additional_phones
      
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index "tickets", ["property_id"]
  end
  
  def down
    drop_table :tickets
  end
end
