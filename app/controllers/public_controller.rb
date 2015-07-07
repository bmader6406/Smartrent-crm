class PublicController < ApplicationController
  
  layout false
  
  def nlt
    #params[:nlt_id] = campaignID_epochResidentId
    campaign_id, resident_id = params[:nlt_id].split('_', 2)

    campaign = Campaign.find(campaign_id)
    resident = Resident.with(:consistency => :eventual).find(resident_id[0..-11]).context(campaign.to_root) rescue nil

    timestamp = resident_id[19..-1].to_i #to insert new subject if exist

    if resident

      newsletter = campaign.newsletter_hylet
      property = campaign.property

      resident.unsubscribe_id = resident_id #for reschedule subject

      macro = resident.to_macro(campaign)

      @body_html = newsletter.body_html

      #reschedule message
      custom_subject = newsletter.schedules.detect{|s| s["timestamp"].to_i == timestamp}["subject"]["#{campaign.to_reschedule_id}"] rescue nil
      subject = custom_subject || newsletter.subject

      title = @body_html.scan(/<title>(.*?)<\/title>/i).first

      if title #replace custom_subject if exist, or replace the default Email Subject
        @body_html = @body_html.sub(/<title>(.*?)<\/title>/i, "<title>#{subject}</title>")

      elsif !title #auto append title tag
        title_tag = "<title>#{subject}</title>"
        head_end = @body_html.scan(/<\/\s*head\s*>/i).first

        if head_end
          @body_html = @body_html.gsub(head_end, "#{title_tag} #{head_end}")
        else
          @body_html = "#{title_tag} #{@body_html}"
        end
      end

      macro.keys.each do |var|
        value = macro[var].to_s
        @body_html = @body_html.gsub("{%#{var}%}", value)
        subject = subject.gsub("{%#{var}%}", value) if subject
      end

      add_header_bar(@body_html, subject)

    else
      render :text => "Page Not Found!" and return
    end

  end

  def nlt2 #for test email
    @campaign = Campaign.find(params[:cid])
    @root_campaign = @campaign.to_root
    newsletter = @campaign.newsletter_hylet

    if newsletter.raw_html?
      @body_html = newsletter.body_html
    end

    subject = newsletter.subject
    title = @body_html.scan(/<title>(.*?)<\/title>/i).first

    if title
      @body_html = @body_html.sub(/<title>(.*?)<\/title>/i, "<title>#{subject}</title>")

    else  #auto append title tag
      title_tag = "<title>#{subject}</title>"
      head_end = @body_html.scan(/<\/\s*head\s*>/i).first

      if head_end
        @body_html = @body_html.gsub(head_end, "#{title_tag} #{head_end}")
      else
        @body_html = "#{title_tag} #{@body_html}"
      end

    end

    add_header_bar(@body_html, subject)

    example_page = "<p style='border: 1px solid red; color:red; font-size: 14px !important; width: 300px;
      margin:10px auto !important; text-align: center; background: #FFD9D9;
      padding: 8px 0; font-family: \"Helvetica Neue\",Arial,Verdana,serif'> This is an example page </p>"

    body_end = @body_html.scan(/<\/\s*body\s*>/i).first

    if body_end
      @body_html.gsub!(body_end, "#{example_page} #{body_end}")
    else
      @body_html += example_page
    end

    render :layout => false, :action => "nlt"
  end

  protected

    def add_header_bar(body_html, subject)
      #temp header, will add share, translate feature later
      header_bar = "<style type='text/css'>
          body {
            padding-top: 30px !important;
          }
          #header-bar {
            background: #fff;
            border-bottom: 1px solid #ddd;
            color: #444;
            font-size: 14px;
            font-family: \"Helvetica Neue\",Arial,Verdana,serif;
            padding: 7px 0 3px 0;
            margin: 0;
            position: absolute;
            right: 0;
            top: 0;
            min-height: 20px;
            text-align: center;
            width: 100%;
          }
        </style>
        <div id='header-bar'>Subject: #{subject}</div>"


      body_end = body_html.scan(/<\/\s*body\s*>/i).first

      if body_end
        body_html.gsub!(body_end, "#{header_bar} #{body_end}")
      else
        body_html += header_bar
      end
    end
end
