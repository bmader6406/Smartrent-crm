class ResidentUnitStatusChanger

  def self.queue
    :crm_immediate
  end

  def self.perform(time = nil)
    time = Time.parse(time) if time.kind_of?(String)
    for_date = (time || Time.now).to_date
    
    ::Resident.or({"units.move_in" => for_date}, {"units.move_out" => for_date}).each do |r|
      r.units.each do |p|
        pp "move_in: #{p.move_in}, move out: #{p.move_out}"
        p.check_and_update_resident_status
        p.save
      end
    end
  end

end
