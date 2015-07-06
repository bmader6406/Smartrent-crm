require 'open-uri'

class Notifier < ActionMailer::Base
  
  
  def campaign_newsletter(campaign, newsletter, entry, form_fields, property_fields, custom_macros, meta)
    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])
    
    newsletter.subject = meta[:custom_subject] if meta[:custom_subject]
    
    macro = resident.to_macro(campaign, form_fields, property_fields, meta[:booking_event])
    
    if !custom_macros.empty?
      custom_macros.each do |cm|
        macro["#{cm.name}"] = cm.values[macro[cm.origin_macro.gsub(/\{%|%\}/, "")]]
      end
    end
    
    translate_macro(campaign, newsletter, macro, entry)
    
    @attachment_urls.split(',').each do |url|
      url = url.strip
      attachments[url.split('/').last] = open(url).read
    end
    
    tracking_img = "<img src='#{"http://#{campaign.email_domain}/pixel?cid=#{campaign.id}&eid=#{resident.id}"}'/>"
    body_end = @body_html.scan(/<\/\s*body\s*>/i).first
    
    if body_end
      @body_html.gsub!(body_end, "#{tracking_img} #{body_end}")
    else
      @body_html += tracking_img
    end
    
    #bcc to hy.ly team or universal recipients
    @bcc = [meta[:bcc_emails], @bcc].flatten.compact.uniq.join(', ')

    mail(:to => resident.email, :from => @sender, :subject => @subject, :cc => @cc, :bcc => @bcc, :reply_to => @reply_to, :delivery_method => meta[:delivery_method] )
    
  end
  
      
  def test_campaign_newsletter(campaign, meta)
  
    Notifier.with_custom_smtp_settings(SMTP_ACCOUNTS[:notifications])

    campaign.property.lead_def.custom_macros.each do |m|
      meta[:dict]["{%#{m.name}%}"] = m.values[meta[:dict][m.origin_macro]]
    end if campaign.property && campaign.property.lead_def
    
    # Create hy.ly tracking urls
    # temporary assign body html/text to the newsletter hylet to 
    # generate the urls. DO NOT save the newseltter
    newsletter = campaign.newsletter_hylet
    newsletter.body_html = meta[:body_html]
    newsletter.body_plain = meta[:body_plain]
    
    url_hash = newsletter.tracking_urls
    
    ###
    
    subject = scan_and_translate_macro(meta[:subject], meta[:dict])
    from = scan_and_translate_macro(meta[:from], meta[:dict])
    cc = scan_and_translate_macro(meta[:cc], meta[:dict])
    bcc = scan_and_translate_macro(meta[:bcc], meta[:dict])
    reply_to = scan_and_translate_macro(meta[:reply_to], meta[:dict])
    body_html = scan_and_translate_macro(meta[:body_html], meta[:dict])
    body_plain = scan_and_translate_macro(meta[:body_plain], meta[:dict])
    file_urls = scan_and_translate_macro(meta[:attachments], meta[:dict])

    @body_html = body_html
    @body_plain = body_plain
    
    if !url_hash.empty?
      url_hash.keys.sort{|k1, k2| k2.to_s.length <=> k1.to_s.length}.each do |origin_url|
        tracking_url = url_hash[origin_url].gsub(SHARE_HOST, campaign.email_domain)
      
        @body_html.gsub!("'#{origin_url}'", tracking_url)
        @body_html.gsub!("\"#{origin_url}\"", tracking_url)
      
        @body_plain.gsub!("#{origin_url}", tracking_url)
      end
    end
    
    #add comment to body html
    if !meta[:comment].blank?
      
      comment_box = "<div id='hl-comment' style='padding: 10px; margin: 10px; background-color: #f9f9f9; border: 1px dashed #ccc; font-size: 14px;'>
        <span style='text-decoration: underline;'>Comment:</span><br><br> #{meta[:comment]} </div><br>"
      
      body_start = @body_html.scan(/<\s*body\s*>/i).first 

      if body_start
        @body_html.gsub!(body_start, "#{body_start} #{comment_box}")
      else
        @body_html = "#{comment_box} #{@body_html}"
      end
    end
    
    send_history = campaign.send_histories.new({
      :to => meta[:to],
      :prefix => meta[:prefix],
      :comment => meta[:comment],
      :origin_prefix => meta[:origin_prefix],
      :subject => subject,
      :body_html => @body_html,
      :body_plain => @body_plain,
      :resident_id => meta[:resident_id],
      :dict => meta[:origin_dict]
    })
    send_history.id = meta[:send_history_id]
    send_history.save
    
    file_urls.to_s.split(',').each do |url|
      url = url.strip
      attachments[url.split('/').last] = open(url).read
    end
    
    #check if custom sender is verify or not
    #if not send as email-test@hy.ly but raise an error
    # campaign.property is for nimda template test

    verified_sender = true

    if !from.blank? && campaign.property
      from_email = from
      from_email = from_email.scan(/<\S*>/)[0].gsub(/<|>/,'') if from_email.include?("<") && from_email.include?(">")
      
      if !VERIFIED_DOMAINS.include?(from_email.gsub(/.*@/, ""))
        mailer = campaign.page_setting.mailer
        ses = nil
        dynect = nil
          
        if mailer
          if mailer.ses?
            ses = AWS::SES::Base.new( :access_key_id => mailer.access_key, :secret_access_key => mailer.secret_key)
          elsif mailer.dynect?
            dynect = mailer
          end
        else
          ses = AWS::SES::Base.new( :access_key_id => AWS_KEY, :secret_access_key => AWS_SECRET)
        end

        if ses
          verified_sender = ses.addresses.list.result.include?(from_email)

        elsif dynect
          verified_sender = (JSON.parse(RestClient.get 'http://emailapi.dynect.net/rest/json/senders', {
            :params => {:apikey => dynect.access_key}})["response"]["data"]["senders"].collect{|s| s["emailaddress"]} rescue []).include?(from_email)
        end
      
        if !verified_sender && send_history
          send_history.update_attributes(:status => "failure", :reason => "From email \"#{from_email}\" is not verified")
          from = "email-test@hy.ly"
        end
      end
    end
    
    sender = !from.blank? ? from : from_address

    mail(:to => meta[:to], :from => sender, :subject => subject, :cc => cc, :bcc => bcc, :reply_to => reply_to, 
      :template_name => 'campaign_newsletter', :delivery_method => meta[:delivery_method])
  end
  
  private
    
    def translate_macro(campaign, newsletter, macro, entry = nil)
      #must clone the original template
      @subject = newsletter.subject.clone
      @from = newsletter.from.clone
      @cc = newsletter.cc.clone
      @bcc = newsletter.bcc.clone
      @reply_to = newsletter.reply_to.clone
      @body_html = @body_html || newsletter.body_html.clone
      @body_plain = @body_plain || newsletter.body_plain.clone
      @attachment_urls = newsletter.attachments.to_s.clone

      header_macro = newsletter.header_macro
      body_macro = newsletter.body_macro

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
      
      if entry
        url_hash = newsletter.tracking_urls

        if !url_hash.empty?
          url_hash.keys.sort{|k1, k2| k2.to_s.length <=> k1.to_s.length}.each do |origin_url|
            tracking_url = url_hash[origin_url].gsub(SHARE_HOST, campaign.email_domain) + "?eid=#{resident.id}"
            tracking_url += "&cid=#{campaign.id}" if campaign.kind_of?(NewsletterRescheduleCampaign)

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
