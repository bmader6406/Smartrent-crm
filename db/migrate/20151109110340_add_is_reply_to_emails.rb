class AddIsReplyToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :is_reply, :boolean, :default => false
  end
end
