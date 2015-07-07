class PropertySetting < ActiveRecord::Base
  belongs_to :property

  before_create :set_time_zone  
  
  serialize :notification_emails, Array
  serialize :spamish_emails, Array
  serialize :universal_recipients, Array
  
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
  
  def self.app_setting
    @app_setting ||= begin
      PropertySetting.find_or_initialize_by(:property_id => nil)
    end
  end
  
  private
  
    def set_time_zone
      self.time_zone = UtcOffset.friendly_identifier(-5)
    end
  
  
end
