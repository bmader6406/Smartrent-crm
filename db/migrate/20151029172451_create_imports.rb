class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :type
      t.text :ftp_setting
      t.text :field_map
      t.boolean :active, :default => false

      t.timestamps null: false
    end
  end
end
