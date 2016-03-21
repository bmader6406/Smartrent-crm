class CreateImportAlerts < ActiveRecord::Migration
  def change
    create_table :import_alerts do |t|
      t.integer :property_id
      t.string :unit_code
      t.string :tenant_code
      t.string :email
      t.boolean :acknowledged, :default => false
      t.datetime :acknowledged_at
      
      t.integer :actor_id

      t.timestamps null: false
    end
  end
end
