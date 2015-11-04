class ResidentSource
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :unit_id, :type => String
  field :property_id, :type => String
  
  field :status, :type => String
  field :status_date, :type => DateTime #don't change to date, property iq require datetime
  
  # these fields should be identical to the resident_property
  # - the source record will keep up the *history* of resident_property
  
  field :type, :type => String
  field :signing_date, :type => Date
  field :move_in, :type => Date
  field :move_out, :type => Date
  field :rent, :type => Integer
  
  field :lead_source, :type => String
  
  # extra
  field :tenant_code, :type => String #yardi ID
  
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

  field :vehicles_count, :type => Integer
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
  

  embedded_in :resident

  # because mongoid 2.4.12 does not support cascading callback on parent object
  # so make sure we make changes to the embedded document directly to trigger the callbacks
  after_create :create_unit, :if => lambda { |s| s.property_id }
  after_create :increase_counter_cache, :if => lambda { |s| !s.unify_resident }
  after_create :create_activity, :if => lambda { |s| !s.unify_resident }

  after_destroy :decrease_counter_cache
  after_destroy :destroy_dependent

  attr_accessor :unify_resident

  def property
    @property ||= Property.find_by_id(property_id)
  end

  def property=(prop) #eager load
    @property = prop
  end

  private

    def create_activity
      #pp ">>>>> create_activity"
      resident.activities.create(:action => "add_new") if resident.activities_count.zero? #if must be here
    end
    
    def create_unit
      #pp ">>> create_unit"
      attrs = { :property_id => property_id }
      
      # save & update NOT BLANK unit fields only
      Resident::UNIT_FIELDS.each do |f|
        if self[f].kind_of?(String) && !self[f].blank?
          attrs[f] = self[f]
          
        elsif self[f]
          attrs[f] = self[f]
          
        end
      end
    
      if !status_date.blank? && !status.blank?
        attrs[:status] = status
        attrs[:status_date] = status_date
      end
      
      ##Code to cater the minimum move in
      # TODO: check smartrent to see why we need to have minimum_move_in
      # minimum_move_in = resident.sources.collect{|s| s.move_in if !s.move_in.blank?}.compact.sort.first
      # attrs[:move_in] = minimum_move_in if minimum_move_in
    
      existing = resident.units.detect{|u| u.property_id == property_id && u.unit_id == unit_id && !unit_id.blank? }

      if existing
        existing.update_attributes(attrs)
        
        if !existing.errors.empty?
          pp "resident_id: #{resident.id} > create_unit > update error:", existing.errors.full_messages.join(", ")
        end
        
      else
        unit = resident.units.create(attrs)
        
        if !unit.errors.empty?
          pp "resident_id: #{resident.id} > create_unit > create error:", unit.errors.full_messages.join(", ")
        end
      end
      
      true
    end
  
    def increase_counter_cache
      #pp ">>>>> increase_counter_cache"
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"sources_count" => 1}}, {:multi => true})
    end

    def decrease_counter_cache
      #pp ">>>>> decrease_counter_cache"
      if resident #when delete all sources, resident will be nil
        Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"sources_count" => -1}}, {:multi => true})
      end
    end
  
    def destroy_dependent
      #pp ">>>>> destroy_dependent"
      if property_id
        if !resident.sources.where(:property_id => property_id, :_id.ne => id.to_s).first
          ep = resident.units.where(:property_id => property_id).first
          ep.destroy if ep
        end
      end
    
    end
  
end
