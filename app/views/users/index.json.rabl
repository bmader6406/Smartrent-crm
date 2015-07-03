node(:total) {|m| @users.total_entries }

child @users, :root => :items, :object_root => false do
  extends "users/show"
end