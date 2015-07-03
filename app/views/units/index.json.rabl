node(:total) {|m| @units.total_entries }

child @units, :root => :items, :object_root => false do
  extends "units/show"
end