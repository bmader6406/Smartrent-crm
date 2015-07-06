class SystemMessageMailer < QueuedMailer

  def self.queue
    :crm_immediate
  end
  
  def self.perform(subject, message, email = nil, meta = {})
    email = Notifier::ADMIN_ADDRESS if email.blank?
    Notifier.system_message(subject, message, email, meta).deliver
  end
  
end
