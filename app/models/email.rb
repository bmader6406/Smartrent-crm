class Email < ActiveRecord::Base

  belongs_to :comment
  
  validates :comment_id, :subject, :from, :to, :message, :presence => true
  validates :from, :to, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  
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