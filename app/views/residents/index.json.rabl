node(:total) {|m| @total_residents }

child @residents, :root => :items, :object_root => false do
  extends "residents/show"
end