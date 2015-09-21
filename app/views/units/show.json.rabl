object @unit

node do |n|
  {
    :id_url => link_to(n.id, property_unit_path(@property, n)),
    :show_path => property_unit_path(@property, n),
    :residents_path => residents_property_unit_path(@property, n),
    :edit_path => edit_property_unit_path(@property, n)
  }
end

attributes *Unit.column_names