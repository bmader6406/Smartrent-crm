class ResidentUnitStatusChecker

  def self.queue
    :crm_immediate
  end

  def self.perform(time)
    time = Time.parse(time) if time.kind_of?(String)
    for_date = (time || Time.now).to_date
    
    ::Resident.or({"units.move_in" => for_date}, {"units.move_out" => for_date}).each do |r|
      r.units.each do |p|
        pp "move_in: #{p.move_in}, move out: #{p.move_out}"
        p.set_unit_status
        p.save
      end
    end
    
    Notifier.system_message("[CRM] ResidentUnitStatusChecker - SUCCESS", "Executed at #{Time.now}", Notifier::DEV_ADDRESS).deliver_now
  end

end
