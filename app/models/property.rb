class Property < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :region
  
  has_one :property_setting
  
  validates :name, :presence => true
  
  resourcify
  
  after_create :create_admin_role
  
  def setting
    @setting ||= begin
      property_setting ? property_setting : create_property_setting(:notification_emails => [user.email])
    end
  end
  
  private
  
    def create_admin_role
      # if user
      #   user.add_role :admin, Property
      # end
    end
  
end
