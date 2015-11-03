node(:total) {|m| @total_residents }

node(:rows) {
  @residents.collect do |d|
    partial("residents/row", :object => d)[:row]
  end
}