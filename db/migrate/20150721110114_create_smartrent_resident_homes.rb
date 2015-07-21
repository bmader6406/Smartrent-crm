class CreateSmartrentResidentHomes < ActiveRecord::Migration
  def change
    create_table :smartrent_resident_homes do |t|
      t.integer :resident_id
      t.integer :home_id

      t.timestamps null: false
    end
  end
end
