node(:total) {|m| @tickets.total_entries }

child @tickets, :root => :items, :object_root => false do
  extends "tickets/show"
end