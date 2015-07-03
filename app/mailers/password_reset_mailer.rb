class PasswordResetMailer
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(user_id)
    user = User.find(user_id)
  
    Notifier.password_reset(user).deliver_now
  end

end