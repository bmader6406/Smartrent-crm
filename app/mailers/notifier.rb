require 'open-uri'

class Notifier < ActionMailer::Base

  BCC_ADDRESS = "help@hy.ly"
  FROM_ADDRESS = "noreply@hy.ly"
  ADMIN_ADDRESS = "admin@hy.ly"
  DEV_ADDRESS = "tn@hy.ly"
  EXIM_ADDRESS = "CRM Exports-Imports <exim@hy.ly>"
  SYS_ADDRESSES = ["exim@hy.ly", "alerts@hy.ly", "renewals@hy.ly", "help@hy.ly", "reports@hy.ly", "reports2@hy.ly", "notifications@hy.ly"]
  
  default :return_path => "ses@hy.ly"
  
  def system_message(subj, message, email, meta = {})
  
    @message = message
    
    attachments[meta["filename"]] = {:content => meta["csv_string"]} if meta["filename"]
    
    mail(:to => email, :from => meta["from"] || from_address, :bcc => meta["bcc"], :reply_to => meta["reply_to"], :subject => "#{ABBR_ENV}#{subj}" )
  end

  def password_reset(user)
    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])  

    @user = user

    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}Reset your CRM password ")
  end

  def password_change(user)
    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])  

    @user = user

    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}Your CRM password has been reset")
  end

  def manager_invitation(manager)

    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])  


    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}You have been invited to manage #{@property.name}'s CRM " )
  end
  
  def email_conversation(subject, message, email, meta = {})
    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])  
    @message = message
    
    mail(:to => email, :from => meta["from"], :subject => subject, :bcc => meta["bcc"], :reply_to => meta["reply_to"])
  end
  
  private

    def self.with_custom_smtp_settings(settings)
      ActionMailer::Base.smtp_settings = ActionMailer::Base.smtp_settings.merge(settings)
    end
  
    def from_address
  
      email = ActionMailer::Base.smtp_settings[:user_name]
    
      @from_name ||= case email
        when "alerts@hy.ly"
          "CRM Alert"
        when "renewals@hy.ly"
          "CRM Renewal"
        when "help@hy.ly"
          "CRM Help"
        when "reports@hy.ly"
          "CRM Report"
        when "reports2@hy.ly"
          "CRM Report"
        when "notifications@hy.ly"
          "CRM Notification"
      end
    
      "#{@from_name} <#{email}>"      
    end
  
end