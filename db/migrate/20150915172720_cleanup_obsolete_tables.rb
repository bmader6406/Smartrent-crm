class CleanupObsoleteTables < ActiveRecord::Migration
  def up
    drop_table :smartrent_users
    drop_table :smartrent_properties
    drop_table :smartrent_articles
  end
end
