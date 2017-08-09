class Email < ActiveRecord::Base

  belongs_to :comment
  
  validates :comment_id, :subject, :from, :to, :message, :presence => true
  validates :from, :to, :presence => true
  
  validate :validate_email_format

  def validate_email_format
    regex = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
    
    ["from", "to", "cc"].each do |f|
      self[f].to_s.split(",").each do |email|
        if !email.to_s.strip.gsub(/(.*<|>.*)/, '').match(regex)
          errors.add(f.to_sym, "#{email} is not valid")
        end
      end
    end
  end
  
  before_create :generate_token
  
  def reply_to
    "crm.conversation+rep#{token}@#{EMAIL_DOMAIN}"
  end
  
  def generate_token(length=10)
    alphanumerics = ('A'..'Z').to_a.concat(('a'..'z').to_a)
    self.token = "#{alphanumerics.sort_by{rand}.join[0..length]}"
    # Ensure uniqueness of the token..
    generate_token unless Email.find_by_token(self.token).nil?
    true
  end
  
end
