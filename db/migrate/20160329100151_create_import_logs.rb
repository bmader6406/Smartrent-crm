class CreateImportLogs < ActiveRecord::Migration
  def change
    create_table :import_logs do |t|
      t.integer :import_id
      t.string :file_path
      t.text :stats

      t.timestamps null: false
    end
  end
end
