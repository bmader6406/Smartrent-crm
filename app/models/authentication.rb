class Authentication < ActiveRecord::Base
  
  
  belongs_to :user
  validates :uid, :provider, :presence => true
  validates :uid, :uniqueness => {:scope => :provider}
  
  def icon
    case provider
      when "google_oauth2"
        "auth/google_32.png"
      else
        "auth/#{provider}_32.png"
    end
  end
  
end
