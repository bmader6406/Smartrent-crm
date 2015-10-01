class Email < ActiveRecord::Base

  belongs_to :comment
  
  validates :comment_id, :subject, :from, :to, :message, :presence => true
  validates :from, :to, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validate :validate_cc_emails

  def validate_cc_emails
    if cc.present?
      emails = cc.split(",")
      if emails.present?
        emails.each do |email|
          email = email.strip
          if email.present? && !Devise::email_regexp.match(email)
            errors.add(:cc, "#{email} is not valid")
          end
        end
      end
    end
  end
  
  before_create :generate_token
  
  def reply_to
    "conversation+rep#{token}@hy.ly" #C0nversation
  end
  
  def generate_token(length=10)
    alphanumerics = ('A'..'Z').to_a.concat(('a'..'z').to_a)
    self.token = "#{alphanumerics.sort_by{rand}.join[0..length]}"
    # Ensure uniqueness of the token..
    generate_token unless Email.find_by_token(self.token).nil?
    true
  end
  
end
