class User < ActiveRecord::Base
  has_many :authentications
  has_many :properties
  
  validates :first_name,  :presence => true
  validates :email, :presence => true, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => lambda { |user| user.enable_validation }
  
  attr_accessor :enable_validation, :password_confirmation
  
  rolify
  
  acts_as_authentic do |c| 
    c.login_field = :email

    c.ignore_blank_passwords = true
    c.validate_login_field = false
    c.validate_password_field = false
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end
  
  
  validate do |user|
    if user.password_required?
      if user.new_record? #adds validation if it is a new record
        user.errors.add(:password, "is required") if user.password.blank?
        user.errors.add(:password_confirmation, "is required") if user.password_confirmation.blank?
        user.errors.add(:password, "Password and confirmation must match") if user.password != user.password_confirmation
      
      elsif !(!user.new_record? && user.password.blank? && user.password_confirmation.blank?) #adds validation only if password or password_confirmation are modified
        user.errors.add(:password, "is required") if user.password.blank?
        user.errors.add(:password_confirmation, "is required") if user.password_confirmation.blank?
        user.errors.add(:password, " and confirmation must match.") if user.password != user.password_confirmation
        user.errors.add(:password, " and confirmation should be atleast 4 characters long.") if user.password.length < 4 || user.password_confirmation.length < 4
      end
    end
  end
  
  def apply_omniauth(omniauth)
    self.email = omniauth['info']['email'] if email.blank?
    self.full_name = omniauth['info']['name'] if full_name.blank?
    self.full_name = [omniauth['info']['first_name'], omniauth['info']['last_name']].join(" ") if full_name.blank?

    authentications.build({
      :provider => omniauth['provider'], 
      :uid => omniauth['uid'], 
      :name => omniauth['info']['name'],
      :oauth_token => omniauth['credentials']["token"],
      :oauth_secret => omniauth['credentials']["secret"]
    })
  end
  
  def deliver_password_reset!
    reset_perishable_token!
    Resque.enqueue(PasswordResetMailer, self.id)
  end
  
  def deliver_password_change!
    reset_perishable_token!
    Resque.enqueue(PasswordChangeMailer, self.id)
  end
  
  def password_required?
    authentications.empty? || !password.blank?
  end
  
  ####
  
  def accept_invite(token)
    m = Manager.where(:token => token, :email => email).first
    
    if m && !m.user_id
      m.update_attribute(:user_id, id)
    end
  end
  
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def full_name=(name)
    self.first_name, self.last_name = name.split(' ', 2)
  end
  
  def last_login
    "Last Login: #{self.current_login_at.day.ordinalize} #{self.current_login_at.strftime("%B, %Y")}" if self.current_login_at
  end
  
  def avatar_url
    !self['avatar_url'].blank? ? self['avatar_url'] : "/images/page_default.png"
  end
  
  def unsubscribe_url
    "#"
  end
  
  def role
    Role::DICT[ (roles.detect{|r| r.resource_type == "Property" && r.resource_id.blank? }.name rescue nil) ]
  end
  
  # helpers
  
  def managed_property_ids
    Property.find_by_sql("select properties.id as pid from properties
      inner join roles on properties.id = roles.resource_id AND roles.resource_type = 'Property'
      inner join users_roles on users_roles.role_id = roles.id AND users_roles.user_id = #{id};
    ").collect{|t| t.pid }
  end
  
  def managed_region_ids
    Region.find_by_sql("select regions.id as rid from regions
      inner join roles on regions.id = roles.resource_id AND roles.resource_type = 'Region'
      inner join users_roles on users_roles.role_id = roles.id AND users_roles.user_id = #{id};
    ").collect{|t| t.rid }
  end
  
  def managed_properties
    @managed_properties ||= begin
      if has_role? :admin, Property
        Property.all
        
      elsif has_role? :regional_manager, Property
        Property.where(:region_id => managed_region_ids)
            
      else
        Property.where(:id => managed_property_ids)
        
      end
    end
  end
  
  # memo:
  # def find_property_by_id(id)
  #   managed_properties.find(id)
  # end
  
end