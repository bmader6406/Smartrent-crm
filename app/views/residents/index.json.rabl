node(:total) {|m| @residents.total_entries }

child @residents, :root => :items, :object_root => false do
  extends "residents/show"
end