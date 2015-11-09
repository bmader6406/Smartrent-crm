class AddImportAlertIdToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :import_alert_id, :integer
  end
end
