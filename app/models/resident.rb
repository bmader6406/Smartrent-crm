# note: because of the replication lag, we will switch between primary, secondary manually
#  Resident.with(:consistency => :strong): read from primary
#  Resident.with(:consistency => :eventual): read from secondary
#  (mongoid will auto switch to primary on save/update/destroy)
#
#  !!! The backup server must be a hidden member of the replica set
class Resident
  include Mongoid::Document
  include Mongoid::Timestamps

  include MultiTenant::RandomPrimaryKeyHelper
  
  CORE_FIELDS = [:email, :last_name, :first_name, :full_name, :gender, :birthday, :ssn, :last4_ssn, :alt_email,
    :primary_phone, :cell_phone, :home_phone, :work_phone, :street, :city, :state, :zip, :country]
    
  PROPERTY_FIELDS = [:property_id, :unit_id, :status, :status_date, :type, :signing_date, :move_in, :move_out, :rent,
    :household_size, :household_status, :moving_from, :pets_count, :pet_type, :pet_breed, :pet_name, :occupation_type, :employer, 
    :employer_city, :employer_state, :annual_income,  :minutes_to_work, :transportation_to_work, 
    :vehicle1, :license1, :vehicle2, :license2, :vehicles_count, :badge_number, :rental_type,
    :lessee, :roommate, :arc_check, :occupant_type, :relationship, :office_phone, :fax, :work_hour, :other1, :other2, :other3, :other4, :other5 ]
    
  field :_id, :type => String
  
  field :unified_status, :type => String #for group/property
  
  field :sources_count, :type => Integer, :default => 0
  field :properties_count, :type => Integer, :default => 0
  field :activities_count, :type => Integer, :default => 0
  
  field :deleted_at, :type => DateTime
  
  #core info
  field :email, :type => String
  field :last_name, :type => String
  field :first_name, :type => String

  field :email_lc, :type => String
  field :last_name_lc, :type => String
  field :first_name_lc, :type => String
  
  field :gender, :type => String
  field :birthday, :type => Date
  field :primary_phone, :type => String
  field :cell_phone, :type => String
  field :home_phone, :type => String
  field :work_phone, :type => String
  
  field :street, :type => String
  field :city, :type => String
  field :state, :type => String
  field :zip, :type => String
  field :country, :type => String
  
  field :ssn, :type => String
  field :last4_ssn, :type => String
  field :alt_email, :type => String
  
  embeds_many :activities, :class_name => "ResidentActivity"
  embeds_many :sources, :class_name => "ResidentSource"
  embeds_many :properties, :class_name => "ResidentProperty"

  accepts_nested_attributes_for :activities, :sources, :properties

  before_save :downcase_name_email
  
  index({ email_lc: 1 }, {background: true})
  index({ first_name_lc: 1 }, {background: true})
  index({ last_name_lc: 1 }, {background: true})

  #embedded
  index({ "properties.property_id" => 1, "properties.status" => 1 })
  index({ "properties.property_id" => 1, :updated_at => 1 })
  
  index({ "properties.property_id" => 1, "properties.unit_id" => 1 })

  scope :ordered, ->(*order) { order_by(order.flatten.first ? order.flatten.first.split(" ") : {:created_at => :desc})}
  scope :unify_ordered, -> { order_by({:created_at => :asc}) }
  
  attr_accessor :curr_property_id, :property_id, :from_import
  
  # don't set default sort order
  # don't specify sort if not needed on a large set
  # http://stackoverflow.com/questions/11599069/what-does-mongo-sort-on-when-no-sort-order-is-specified

  def self.find_by_id(id)
    Resident.where(:_id => id.to_i).first
  end
  
  def curr_source(pid = curr_property_id)
    @curr_source ||= ordered_sources.reverse.detect{|s| s.property_id.to_s == pid.to_s }
  end
  
  def curr_property(pid = curr_property_id)
    @curr_property ||= properties.detect{|p| p.property_id.to_s == pid.to_s }
  end
  
  def property=(data)
    pp "property data: #{data}" #do nothing
  end
  
  def tickets
    @tickets ||= Ticket.where(:resident_id => id)
  end

  #==== relationship between mysql, mongodb document


  def eager_load(subject)
    # if subject.kind_of?(X)

    # end
  
    self
  end
  
  # order by created_at desc
  def ordered_activities
    @ordered_activities ||= activities.sort{|a, b| b.created_at <=> a.created_at}
  end
  
  # TODO: add activity archiver once activity list grow big
  def archived_activities(skip = 0, limit = 100)
    ArchivedResidentActivity.where(:resident_id => id.to_s).order_by(:created_at => :desc).skip(skip).limit(limit).collect{|a| activities.new(a.to_attrs) } # DO NOT SAVE entry
  end

  def total_activities_count
    activities.length + ArchivedResidentActivity.where(:resident_id => id.to_s).count
  end

  # order by created_at asc
  def ordered_sources
    @ordered_sources ||= sources.sort{|a, b| a.created_at <=> b.created_at}
  end

  #==== methods

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def full_name=(name)
    self.first_name, self.last_name = name.split(' ', 2)
  end

  def status_dict
    @status_dict ||= {
      "resident_current" => "Resident - Current",
      "resident_future" => "Resident - Future",
      "resident_past" => "Resident - Past",
      "resident_notice" => "Resident - Notice",
      "" => "N/A",
      nil => "N/A",
    }
  end
  
  #for resident cleaner, resident sub-org callback
  def to_unified_status
    status = nil
    statues = []

    properties.each{|prop| statues << prop.status }

    if statues.any? {|s| s == "Current"}
      status = "resident_current"

    elsif statues.any? {|s| s == "Future"}
      status = "resident_future"

    elsif statues.any? {|s| s == "Past"}
      status = "resident_past"

    elsif statues.any? {|s| s == "Notice"}
      status = "resident_notice"

    end
  
    status
  end

  private
  
    def downcase_name_email
      self.first_name_lc = first_name.downcase if first_name
      self.last_name_lc = last_name.downcase if last_name
      self.email_lc = email.downcase if email
    end
end