class PropertySetting < ActiveRecord::Base
  belongs_to :property
  before_create :set_time_zone    
  
  serialize :notification_emails, Array

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
