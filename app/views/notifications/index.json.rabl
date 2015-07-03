node(:total) {|m| @notifications.total_entries }

child @notifications, :root => :items, :object_root => false do
  extends "notifications/show"
end