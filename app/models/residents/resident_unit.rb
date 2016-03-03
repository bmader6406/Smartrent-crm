class ResidentUnit

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  
  field :unit_id, :type => String
  field :property_id, :type => String
  
  field :status, :type => String
  field :status_date, :type => DateTime #don't change to date, property iq require datetime
  
  # property/source info
  # source keeps the history of changes
  # unit keeps the last changes
  # - resident can live in mutiple units of the same property, result in mutiple units with diferrent unit_id
  # - if we want to check the move in/out history, changed fields... check the resident_source

  field :type, :type => String
  field :signing_date, :type => Date
  field :move_in, :type => Date
  field :move_out, :type => Date
  field :rent, :type => Integer
  
  field :lead_source, :type => String
  
  # extra
  field :tenant_code, :type => String # Yardi ID
  
  # demographics
  field :household_size, :type => String
  field :household_status, :type => String
  field :moving_from, :type => String
  field :pets_count, :type => Integer

  field :pet_1_type, :type => String
  field :pet_1_breed, :type => String
  field :pet_1_name, :type => String

  field :pet_2_type, :type => String
  field :pet_2_breed, :type => String
  field :pet_2_name, :type => String

  field :pet_3_type, :type => String
  field :pet_3_breed, :type => String
  field :pet_3_name, :type => String

  field :occupation_type, :type => String
  field :employer, :type => String
  field :employer_city, :type => String
  field :employer_state, :type => String
  field :annual_income, :type => Float
  
  field :previous_residence, :type => String
  
  #vehicle info
  field :minutes_to_work, :type => String
  field :transportation_to_work, :type => String
  field :vehicles_count, :type => Integer

  field :vehicle1, :type => String
  field :license1, :type => String
  field :badge_number_1, :type => String

  field :vehicle2, :type => String
  field :license2, :type => String
  field :badge_number_2, :type => String

  field :vehicle3, :type => String
  field :license3, :type => String
  field :badge_number_3, :type => String

  field :vehicle4, :type => String
  field :license4, :type => String
  field :badge_number_4, :type => String

  field :vehicle5, :type => String
  field :license5, :type => String
  field :badge_number_5, :type => String
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
  
  embedded_in :resident
  
  validates :property_id, :status , :move_in, :unit_id, :presence => true

  before_save :set_rental_type
  before_save :set_unit_status
  
  after_save :set_unified_status
  after_save :create_or_update_smartrent_resident
  
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
  
  def unit_code
    @unit_code ||= ( @unit || Unit.find(unit_id) ).code rescue nil
  end

  #====
  
  def set_unit_status
    if move_out.present? && move_in.present?
      if move_in <= Time.now && move_out >= Time.now
        self.status = "Current"
        
      elsif move_in >= Time.now && move_out >= Time.now
        self.status = "Future"
        
      elsif move_in <= Time.now && move_out <= Time.now
        self.status = "Past"
      end
    end
  end
  
  private

    def increase_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"units_count" => 1}}, {:multi => true})
    end

    def decrease_counter_cache
      if resident #when delete all properties, resident will be nil
        Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"units_count" => -1}}, {:multi => true})
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
    
    def create_or_update_smartrent_resident
      Resque.enqueue(Smartrent::ResidentCreator, resident._id, _id.to_s) if !roommate? && property.is_smartrent? && move_in && move_in.to_time <= Time.now
    end

end
