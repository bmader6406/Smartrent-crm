class ResidentProperty

  include Mongoid::Document
  include Mongoid::Timestamps

  field :property_id, :type => String
  field :status, :type => String
  field :status_date, :type => DateTime #don't change to date, property iq require datetime
  
  # property/source info
  # source keeps the history of changes
  # property keeps the last changes
  field :type, :type => String
  field :signing_date, :type => Date
  field :move_in, :type => Date
  field :move_out, :type => Date
  field :rent, :type => Integer
  
  # extra
  field :unit_id, :type => String
  
  # demographics
  field :household_size, :type => String
  field :household_status, :type => String
  field :moving_from, :type => String
  field :pets_count, :type => Integer
  field :pet_type, :type => String
  field :pet_breed, :type => String
  field :pet_name, :type => String
  field :occupation_type, :type => String
  field :employer, :type => String
  field :employer_city, :type => String
  field :employer_state, :type => String
  field :annual_income, :type => Float
  
  #vehicle info
  field :minutes_to_work, :type => String
  field :transportation_to_work, :type => String
  field :vehicle1, :type => String
  field :license1, :type => String
  field :vehicle2, :type => String
  field :license2, :type => String
  field :vehicles_count, :type => Integer
  field :badge_number, :type => String
  field :rental_type, :type => String
  
  # roommates
  field :lessee, :type => Boolean
  field :roommate, :type => Boolean
  field :arc_check, :type => Boolean
  field :occupant_type, :type => String
  field :relationship, :type => String
  field :office_phone, :type => String
  field :fax, :type => String
  field :work_hour, :type => String
  field :other1, :type => String
  field :other2, :type => String
  field :other3, :type => String
  field :other4, :type => String
  field :other5, :type => String
  
  # for newsletter
  field :subscribed, :type => Boolean, :default => true
  field :subscribed_at, :type => DateTime
  
  # resident score
  field :score, :type => Integer, :default => 0
  field :sends_count, :type => Integer, :default => 0
  field :opens_count, :type => Integer, :default => 0
  field :clicks_count, :type => Integer, :default => 0
  
  
  embedded_in :resident

  before_save :set_rental_type
  
  after_save :set_unified_status
  after_save :update_smartrent_resident
  after_create :increase_counter_cache

  after_destroy :set_unified_status
  after_destroy :decrease_counter_cache

  def property
    @property ||= Property.find_by_id(property_id)
  end

  def property=(prop) #eager load
    @property = prop
  end
  
  def unit
    @unit ||= unit_id.blank? ? nil : Unit.find_by_id(unit_id)
  end

  #====
  
  def finalize_score
    self.score = sends_count*Resident::SEND_SCORE + opens_count*Resident::OPEN_SCORE +  clicks_count*Resident::CLICK_SCORE
    self.save
  end
  
  private

    def increase_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"properties_count" => 1}}, {:multi => true})
    end

    def decrease_counter_cache
      if resident #when delete all properties, resident will be nil
        Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"properties_count" => -1}}, {:multi => true})
      end
    end
  
    def set_unified_status
      if resident && resident.unified_status != resident.to_unified_status # pure update
        Resident.collection.where({"_id" => resident._id}).update({ "$set" => {"unified_status" => resident.to_unified_status }}, {:multi => true})
      end
    end
    
    def set_rental_type
      self.rental_type = unit.rental_type if unit # for reports
    end
    
    def update_smartrent_resident
      Resque.enqueue(SmartrentResidentUpdater, resident._id, _id.to_s) if property.is_smartrent?
    end
end