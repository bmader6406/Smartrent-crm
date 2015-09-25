class ResidentPropertyStatusChanger

  def self.queue
    :crm_immediate
  end

  def self.perform(time = nil)
    time = Time.parse(time) if time.kind_of?(String)
    for_date = (time || Time.now).to_date
    
    ::Resident.or({'properties.move_in' => for_date}, {'properties.move_out' => for_date}).each do |r|
      r.properties.each do |p|
        pp "move_in: #{p.move_in}, move out: #{p.move_out}"
        p.check_and_update_resident_status
        p.save
      end
    end
  end

end
