class PropertySetting < ActiveRecord::Base
  belongs_to :property

  validate :validate_emails

  before_create :set_time_zone  
  
  def notification_emails
    self['notification_emails'].to_s.split(',').collect{|email| email.strip}
  end
  
  def spamish_emails
    self['spamish_emails'].to_s.split(',').collect{|email| email.strip}
  end
  
  def universal_recipients
    self['universal_recipients'].to_s.split(',').collect{|email| email.strip}
  end
  
  #custom mailer
  def mailer
    @mailer ||= mailer_id.blank? ? nil : Mailer.find_by_id(mailer_id)
  end
  
  def delivery_method
    mailer ? "#{mailer.type}_#{mailer.id}".to_sym : :ses
  end
  
  
  
  def default_source_mapping
    [
      {"tag" => "___default___", "name" => "Bozzuto.com"},
      {"tag" => "e", "name" => "Email"},
      {"tag" => "w", "name" => "Web"},
      {"tag" => "l", "name" => "LandingPage"},
      {"tag" => "bozzuto", "name" => "Bozzuto.com"},
      {"tag" => "pws", "name" => "PropertyWebsite"},
      {"tag" => "yelp", "name" => "Yelp.com"},
      {"tag" => "fb", "name" => "SocialMedia"},
      {"tag" => "rwg", "name" => "RentalsGoneWild.com"},
      {"tag" => "hylyemail", "name" => "EmailBlast"}
    ]
  end
  
  # ignore ad url in newsletter
  def ad_domains
    @ad_domains ||= self[:ad_domains].to_s.split(",").collect{|d| d.strip }
  end
  
  private
  
    def validate_emails
      if !notification_emails.all?{|email| email.strip =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
        # TODO: check demo+admin@hy.ly is not valid
        #errors.add(:notification_emails, "is not valid")
      end
    end
    
    def set_time_zone
      self.time_zone = UtcOffset.friendly_identifier(-5)
    end
  
  
end
