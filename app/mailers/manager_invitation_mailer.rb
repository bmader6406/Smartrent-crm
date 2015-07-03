class ManagerInvitationMailer
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(manager_id)
    manager = Manager.find(manager_id)
  
    Notifier.manager_invitation(manager).deliver_now
  end

end