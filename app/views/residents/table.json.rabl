node(:total) {|m| @residents.total_entries }

node(:rows) {
  @residents.collect do |d|
    partial("residents/row", :object => d)[:row]
  end
}