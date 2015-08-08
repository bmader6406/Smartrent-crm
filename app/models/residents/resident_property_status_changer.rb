class ResidentPropertyStatusChanger

  def self.queue
    :crm_immediate
  end

  def self.perform(time = nil)
    ::Resident.where("properties" => {
      "$elemMatch" => {
        #"move_in" => {"$lt" => today},
        #"move_out" => {"$gt" => today},
        "status" => {"$in" => ["Current", "Future", "Past"]}
      }
    }).each do |r|
      r.properties.each do |p|
        p.check_and_update_resident_status
        p.save
      end
    end
  end

end
