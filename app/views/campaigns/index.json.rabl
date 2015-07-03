node(:total) {|m| @campaigns.total_entries }

child @campaigns, :root => :items, :object_root => false do
  extends "campaigns/show"
end