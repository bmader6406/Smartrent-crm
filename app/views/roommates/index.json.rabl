if params[:unit_id]
  collection @roommates
  extends "roommates/show"
else
  node(:total) {|m| @roommates.total_entries }

  child @roommates, :root => :items, :object_root => false do
    extends "roommates/show"
  end
end