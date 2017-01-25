class SystemMessageMailer < QueuedMailer

  def self.queue
    :crm_immediate
  end
  
  def self.perform(subject, message, email = nil, meta = {})
    email = ADMIN_EMAIL if email.blank?
    Notifier.system_message(subject, message, email, meta).deliver_now
  end
  
end
