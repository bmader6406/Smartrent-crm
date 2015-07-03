node(:total) {|m| @properties.total_entries }

child @properties, :root => :items, :object_root => false do
  extends "properties/show"
end