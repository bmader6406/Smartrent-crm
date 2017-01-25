require 'open-uri'

class Notifier < ActionMailer::Base
  default :return_path => OPS_EMAIL
  
  def system_message(subj, message, email, meta = {})
    @message = message
    
    attachments[meta["filename"]] = {:content => meta["csv_string"]} if meta["filename"]
    
    mail(:to => email, :from => meta["from"] || from_address, :bcc => meta["bcc"], :reply_to => meta["reply_to"], :subject => "#{ABBR_ENV}#{subj}" )
  end

  def password_reset(user)
    @user = user

    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}Reset your CRM password ")
  end

  def password_change(user)
    @user = user

    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}Your CRM password has been reset")
  end

  def manager_invitation(manager)
    mail(:to => @user.email, :from => from_address, :subject => "#{ABBR_ENV}You have been invited to manage #{@property.name}'s CRM " )
  end
  
  def email_conversation(subject, message, email, meta = {})
    @message = message
    
    mail(:to => email, :from => meta["from"], :subject => subject, :cc => meta["cc"], :bcc => meta["bcc"], :reply_to => meta["reply_to"])
  end
  
  def campaign_newsletter(campaign, resident, meta)
    macro = resident.to_macro(campaign)
    
    translate_macro(campaign, macro, resident)
    
    @attachment_urls.split(',').each do |url|
      url = url.strip
      attachments[url.split('/').last] = open(url).read
    end
    
    tracking_img = "<img src='#{"https://#{HOST}/pixel?cid=#{campaign.id}&rid=#{resident.id}"}'/>"
    body_end = @body_html.scan(/<\/\s*body\s*>/i).first
    
    if body_end
      @body_html.gsub!(body_end, "#{tracking_img} #{body_end}")
    else
      @body_html += tracking_img
    end
    
    @bcc = [meta[:bcc_emails], @bcc].flatten.compact.uniq.join(', ')

    mail(:to => resident.email, :from => @sender, :subject => @subject, :cc => @cc, :bcc => @bcc, :reply_to => @reply_to )
    
  end
  

  private
    def from_address
      email = ActionMailer::Base.smtp_settings[:user_name]
    
      @from_name ||= case email
        when OPS_EMAIL
          "CRM Alert"
          
        when HELP_EMAIL
          "CRM Help"
      end
    
      "#{@from_name} <#{email}>"      
    end
    
    def translate_macro(campaign, macro, resident = nil)
      #must clone the original template
      @subject = campaign.subject.to_s.clone
      @from = campaign.from.to_s.clone
      @cc = campaign.cc.to_s.clone
      @bcc = campaign.bcc.to_s.clone
      @reply_to = campaign.reply_to.to_s.clone
      @body_html = @body_html || campaign.body_html.to_s.clone
      @body_plain = @body_plain || campaign.body_plain.to_s.clone
      @attachment_urls = campaign.attachments.to_s.clone

      header_macro = campaign.header_macro
      body_macro = campaign.body_macro

      if !header_macro.empty?
        header_macro.each do |um|
          value = macro[um].to_s
          [@subject, @from, @cc,  @bcc, @reply_to, @attachment_urls].each do |var|
            var.gsub!("{%#{um}%}", value) if var
          end
        end
      end

      if !body_macro.empty?
        body_macro.each do |um|
          value = macro[um].to_s
          [@body_html, @body_plain].each do |var|
            var.gsub!("{%#{um}%}", value) if var
          end
        end
      end
      
      if resident
        url_hash = campaign.tracking_urls

        if !url_hash.empty?
          url_hash.keys.sort{|k1, k2| k2.to_s.length <=> k1.to_s.length}.each do |origin_url|
            tracking_url = url_hash[origin_url] + "?rid=#{resident.id}"

            @body_html.gsub!("'#{origin_url}'", tracking_url)
            @body_html.gsub!("\"#{origin_url}\"", tracking_url)

            @body_plain.gsub!("#{origin_url}", tracking_url)
          end
        end
      end
      
      @sender = !@from.blank? ? @from : from_address
    end
    
    def scan_and_translate_macro(var, dict)
      var.scan(/\{%[\w,@,.]*%\}/).each do |macro|
        var = var.gsub("#{macro}", dict[macro] || macro.gsub(/\{%|%\}/, "").upcase) if var
      end
      return var
    end
  
end
