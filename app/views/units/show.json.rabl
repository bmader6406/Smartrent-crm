object @unit

node do |n|
  attrs = {
    :id_url => link_to(n.id, property_unit_path(@property, n)),
    :show_path => property_unit_path(@property, n),
    :residents_path => residents_property_unit_path(@property, n),
    :edit_path => edit_property_unit_path(@property, n),
    :search_resident_path => search_property_residents_path(@property),
    :add_ticket_path => ""
  }
  attrs[:add_ticket_path] = property_resident_path(@property, n.primary_resident.id, :anchor => 'addTicket') if n.primary_resident.present?
  attrs
end
if @unit.present?
  child @unit.primary_resident, :root => :primary_resident do
    extends "residents/show"
  end
end

attributes *Unit.column_names
