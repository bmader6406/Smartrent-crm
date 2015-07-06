class Url < ActiveRecord::Base
  include MultiTenant::RandomPrimaryKeyHelper
  
  belongs_to :campaign

  before_create :generate_token

  def to_tracking_url
    "http://#{SHARE_HOST}/t/#{token}"
  end
  
  private
    
    def generate_token(length=16)
      alphanumerics = ('A'..'Z').to_a.concat(('a'..'z').to_a)
      self.token = "#{alphanumerics.sort_by{rand}.join[0..length]}"
      # Ensure uniqueness of the token..
      generate_token unless Url.find_by_token(self.token).nil?
      true
    end
end
