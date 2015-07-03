class RolifyCreateRoles < ActiveRecord::Migration
  def up
    create_table(:roles) do |t|
      t.string :name
      t.string   :resource_type
      t.integer  :resource_id
      
      t.timestamps
    end

    
    create_table(:users_roles, :id => false) do |t|
      t.integer  :user_id
      t.integer  :role_id
    end

    add_index(:roles, :name)
    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:users_roles, [ :user_id, :role_id ])
  end
  
  def down
    drop_table :users_roles
    drop_table :roles
  end
end
