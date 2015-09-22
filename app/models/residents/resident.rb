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
    :vehicle1, :license1, :badge_number_1, :vehicle2, :license2, :badge_number_2, :vehicle3, :license3, :badge_number_3, :vehicle4, :license4, :badge_number_4, :vehicle5, :license5, :badge_number_5, :vehicles_count, :rental_type,
    :lessee, :roommate, :arc_check, :occupant_type, :relationship, :office_phone, :fax, :work_hour, :other1, :other2, :other3, :other4, :other5 ]
    
  field :_id, :type => String
  
  field :unified_status, :type => String
  
  field :sources_count, :type => Integer, :default => 0
  field :properties_count, :type => Integer, :default => 0
  field :activities_count, :type => Integer, :default => 0
  field :marketing_activities_count, :type => Integer, :default => 0
  
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
  
  # for newsletter
  field :subscribed, :type => Boolean, :default => true
  field :subscribed_at, :type => DateTime
  
  field :email_check, :type => String, :default => "New"
  field :email_checked_at, :type => DateTime
  
  field :bounces_count, :type => Integer, :default => 0
  field :smartrent_resident_id, :type => Integer, :default => nil
  
  # resident score
  SEND_SCORE = 1
  OPEN_SCORE = 2
  CLICK_SCORE = 5
  
  field :score, :type => Integer, :default => 0
  field :sends_count, :type => Integer, :default => 0
  field :opens_count, :type => Integer, :default => 0
  field :clicks_count, :type => Integer, :default => 0
  
  
  embeds_many :activities, :class_name => "ResidentActivity"
  embeds_many :sources, :class_name => "ResidentSource"
  embeds_many :properties, :class_name => "ResidentProperty"
  embeds_many :marketing_activities, :class_name => "MarketingActivity"

  accepts_nested_attributes_for :activities, :sources, :properties, :marketing_activities

  before_save :downcase_name_email
  after_save :change_smartrent_email
  
  index({ email_lc: 1 }, {background: true})
  index({ first_name_lc: 1 }, {background: true})
  index({ last_name_lc: 1 }, {background: true})

  index({ :smartrent_resident_id => 1 }, {background: true})
  
  #embedded
  index({ :deleted_at => 1 })
  index({ "properties.property_id" => 1, "properties.status" => 1 })
  index({ "properties.property_id" => 1, :updated_at => 1 })
  index({ "properties.property_id" => 1, "properties.unit_id" => 1 })

  scope :ordered, ->(*order) { order_by(order.flatten.first ? order.flatten.first.split(" ") : {:created_at => :desc})}
  scope :unify_ordered, -> { order_by({:created_at => :asc}) }
  attr_accessor :curr_property_id, :property_id, :from_import
  validates :email, {:uniqueness => true}

  # don't set default sort order
  # don't specify sort if not needed on a large set
  # http://stackoverflow.com/questions/11599069/what-does-mongo-sort-on-when-no-sort-order-is-specified

  def self.find_by_id(id)
    Resident.where(:_id => id.to_i).first
  end

  # fixed N+1 query
  def unit_code
    @unit_code ||= begin
      if @unit
        @unit.code
      else
        !unit_id.blank? ? (Unit.where(:id => unit_id).first.code rescue "") : nil
      end
    end
  end

  def curr_property(pid = curr_property_id)
    @curr_property ||= properties.detect{|p| p.property_id.to_s == pid.to_s } || properties.first
  end

  def context(campaign)
    #clear previous cache
    @curr_property = nil
    self.property_id = campaign ? campaign.property_id : nil
    self
  end
  
  # access current property method at resident level
  PROPERTY_FIELDS.each do |f|
    define_method "#{f}" do
      curr_property.send(f)
    end
  end
  
  def property=(data)
    pp "property data: #{data}" #do nothing
  end
  
  def tickets
    @tickets ||= Ticket.where(:resident_id => id)
  end

  #==== relationship between mysql, mongodb document


  def eager_load(subject, clzz = nil)
    if subject.kind_of?(Smartrent::Resident)
      @smartrent_resident = subject

    elsif subject.kind_of?(Unit)
      @unit = subject
      
    end
  
    self
  end
  
  # order by created_at desc
  def ordered_activities
    @ordered_activities ||= activities.sort{|a, b| b.created_at <=> a.created_at}
  end
  
  def ordered_marketing_activities
    @marketing_activities ||= marketing_activities.sort{|a, b| b.created_at <=> a.created_at}
  end
  
  # TODO: add activity archiver once activity list grow big
  def archived_activities(skip = 0, limit = 100)
    ArchivedResidentActivity.where(:resident_id => id.to_s).order_by(:created_at => :desc).skip(skip).limit(limit).collect{|a| activities.new(a.to_attrs) } # DO NOT SAVE entry
  end

  def total_activities_count
    activities.length + ArchivedResidentActivity.where(:resident_id => id.to_s).count
  end
  
  def archived_marketing_activities(skip = 0, limit = 100)
    ArchivedMarketingActivity.where(:resident_id => id.to_s).order_by(:created_at => :desc).skip(skip).limit(limit).collect{|a| marketing_activities.new(a.to_attrs) } # DO NOT SAVE entry
  end

  def total_marketing_activities_count
    marketing_activities.length + ArchivedMarketingActivity.where(:resident_id => id.to_s).count
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
  
  #for resident cleaner, resident property callback
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
  
  ### email system
  def subscribed?(property = nil)
    if property
      properties.detect{|p| p.property_id == property.id.to_s }.subscribed? rescue false

    elsif curr_property_id
      properties.detect{|p| p.property_id == curr_property_id.to_s }.subscribed? rescue false

    else
      self[:subscribed]
    end
  end

  def subscribed_text
    subscribed? ? "YES" : "NO"
  end

  def any_subscribed?(property_ids)
    (property_ids.include?(property_id) ? self[:subscribed] : false) || properties.any?{|p| p.subscribed? && property_ids.include?(p.property_id) }
  end

  def unsubscribe(campaign, action = nil)
    #action can be: unsubscribe_confirm, unsubscribe_confirm_all, unsubscribe_blacklisted, unsubscribe_bounce, unsubscribe_complaint
    updated = false

    if ["unsubscribe_confirm_all", "unsubscribe_blacklisted", "unsubscribe_bounce", "unsubscribe_complaint"].include?(action)
      if self.subscribed?
        self.update_attribute(:subscribed, false)
        updated = true
      end

      if properties.any?{|p| p.subscribed }
        self.properties.update_all(:subscribed => false)
        updated = true
      end

    else
      if campaign.property
        prop = properties.detect{|p| p.property_id ==  campaign.property.id.to_s || campaign.tmp_property_id.to_s == p.property_id }

        if prop && prop.subscribed?
          prop.update_attribute(:subscribed, false)
          updated = true

        elsif campaign.tmp_property_id.to_s == property_id && self.subscribed?
          self.update_attribute(:subscribed, false)
          updated = true
        end

      else
        if self.subscribed?
          self.update_attribute(:subscribed, false)
          updated = true
        end
      end

    end

    if updated
      attrs = {:action => action, :subject_id => campaign.id, :subject_type => campaign.class.to_s}
      if campaign.tmp_property_id
        attrs[:target_id] = campaign.tmp_property_id
        attrs[:target_type] = "Property"
      end
      marketing_activities.create(attrs)
    end
  end

  def subscribe(campaign, bozzuto_properties = nil)
    updated = false

    if bozzuto_properties
      bozzuto_properties.each do |property|
        prop = properties.detect{|p| p.property_id ==  property.id.to_s }

        if prop && !prop.subscribed?
          prop.update_attributes(:subscribed => true, :subscribed_at => Time.now.utc)

          marketing_activities.create(:action => "subscribe_property", :subject_id => campaign.id, :subject_type => campaign.class.to_s,
            :target_id => prop.id, :target_type => "Property")
        end
      end

    else
      if campaign.property
        prop = properties.detect{|p| p.property_id ==  campaign.property.id.to_s  || campaign.tmp_property_id.to_s == p.property_id  }

        if prop && !prop.subscribed?
          prop.update_attributes(:subscribed => true, :subscribed_at => Time.now.utc)
          updated = true

        elsif campaign.tmp_property_id.to_s == property_id && !self.subscribed?
          self.update_attributes(:subscribed => true, :subscribed_at => Time.now.utc)
          updated = true

        end

      else
        if !self.subscribed?
          self.update_attributes(:subscribed => true, :subscribed_at => Time.now.utc)
          updated = true
        end
      end

      if updated
        attrs = {:action => "subscribe", :subject_id => campaign.id, :subject_type => campaign.class.to_s}
        if campaign.tmp_property_id
          attrs[:target_id] = campaign.tmp_property_id
          attrs[:target_type] = "Property"
        end
        marketing_activities.create(attrs)
      end
    end

  end
  
  def finalize_score
    self.score = sends_count*SEND_SCORE + opens_count*OPEN_SCORE + clicks_count*CLICK_SCORE
    self.save
  end
  
  def bad_email?
    email.blank? || email_check == "Bad"
  end
  
  def unsubscribe_url
    "http://#{HOST}/unsubscribes/#{unsubscribe_id}"
  end
  
  def unsubscribe_id
    @unsubscribe_id || "#{id}#{Time.now.to_i}"
  end
  
  def unsubscribe_id=(uid) #for reschedule
    @unsubscribe_id = uid
  end
  
  def cookie_id
    "#{id}#{Time.now.to_i}"
  end
  
  def nlt_url(cid) #web version
    "http://#{HOST}/nlt/#{cid}_#{unsubscribe_id}"
  end

  def to_macro(campaign)
    macro = { 
      "first_name" => first_name.to_s,
      "last_name" => last_name.to_s,
      "full_name" => full_name.to_s,
      'email' => email.to_s,
      "unsubscribe_url" => "#{unsubscribe_url}?cid=#{campaign.id}",
      "email_url" => nlt_url(campaign.id),
      "cache_buster_id" => unsubscribe_id
    }
    
    attributes.keys.each do |k|
      macro["#{k}"] = self[k]
    end

    campaign.property.to_macro(macro)

    macro
  end


  # for unsubscribe
  def to_cross_audience(va_campaign)
    property_ids = properties.collect{|p| p.property_id }
    audiences = cross_audiences

    #find sub-org audience which the lead belongs to
    audience = audiences.detect{|a| property_ids.include?(a.property_id.to_s) }

    #find org-group's audience if no sub-org's audience found
    audience = audiences.detect{|a| property_id.to_i == a.property_id } if !audience

    return audience
  end
  
  # @smartrent_resident is used to eager load the smartrent resident
  #TODO:
  # - add index on crm_resident_id
  # - awards point should be stored in database, don't query the db to calculate the point everytime
  def smartrent_resident
    if defined? @smartrent_resident
      @smartrent_resident
    else
      Smartrent::Resident.find_by_crm_resident_id(id)
    end
  end

  private
  
    def downcase_name_email
      self.first_name_lc = first_name.downcase if first_name
      self.last_name_lc = last_name.downcase if last_name
      self.email_lc = email.downcase if email
    end
    
    def change_smartrent_email
      if email_changed? && smartrent_resident
        smartrent_resident.update_attributes(:email => email)
      end
    end
end
