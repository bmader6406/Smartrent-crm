class CampaignReportsController < ApplicationController
  
  before_action :require_user
  before_action :set_campaign
  before_action :set_filter_params
  before_action :set_page_title
  
  @@per_page = 20
  
  def index
    respond_to do |format|
      format.html{
        dashboard_metrics
      }
      format.js {
        dashboard_metrics
      }
    end  
  end

  def subscribers
    per_page = 10
    
    clzzes = {
      "sent" => SendEvent,
      "opened" => UniqueOpenEvent,
      "clicked" => LinkClickEvent,
      "unique_clicked" => UniqueLinkClickEvent,
      "unsubscribed" => UnsubscribeClickEvent,
      "complained" => ComplaintEvent,
      "blacklisted" => BlacklistedEvent,
      "bounced" => BounceEvent,
      "received" => SendEvent
    }
    
    conditions = {:campaign_id => @campaign.multi_sends.collect{|c| c.id } }
    
    if request.xhr?
      
      @events = clzzes[params[:type]].where(conditions)
      @events = @events.where("opened_at IS NULL") if params[:type] == "received"
      
      @events = @events.order("created_at desc").paginate(:page => params[:page], :per_page => per_page).all

      residents = Resident.with(:consistency => :eventual).where(:_id.in => @events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      render :action => "subscribers.js.erb" and return
    else
      #send_events
      @send_events = SendEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @send_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @send_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      
      #open_events
      @open_events = UniqueOpenEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @open_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @open_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      
      #receive_events
      @receive_events = SendEvent.where(conditions).where("opened_at IS NULL").order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @receive_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @receive_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      #click_events
      @click_events = UniqueLinkClickEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @click_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @click_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      #unsubscribe_events
      @unsubscribe_events = UnsubscribeClickEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @unsubscribe_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @unsubscribe_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      #complaint_events
      @complaint_events = ComplaintEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @complaint_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @complaint_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      #blacklisted_events
      @blacklisted_events = BlacklistedEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @blacklisted_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @blacklisted_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}
      
      #bounce_events
      @bounce_events = BounceEvent.where(conditions).order("created_at desc").paginate(:page => params[:page], :per_page => per_page ).all
      
      residents = Resident.with(:consistency => :eventual).where(:_id.in => @bounce_events.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
      @bounce_events.each{|ev| ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id})}

    end
  end
  
  def spam_watch
    if !request.xhr?
      spam_watch_by_audience
      
    else
      spam_watch_by_status # reduce delay time by showing this report on ajax
    end
  end
  
  def spam_watch_by_status
    campaign_ids = @campaign.multi_sends.collect{|c| c.id }
    pp "campaign_ids: ", campaign_ids
    
    hash = {}
    total = {}

    @status_metrics = []
    @status_total = {}
    
    Recipient.find_by_sql("SELECT r.status,
        count(if(e.type='SendEvent', 1, NULL)) AS total_sends,
        count(if(e.type='LinkClickEvent', 1, NULL)) AS total_clicks,
        count(if(e.type='UnsubscribeClickEvent', 1, NULL)) AS total_unsubscribes,
        count(if(e.type='ComplaintEvent', 1, NULL)) AS total_complaints
      FROM events e
      INNER JOIN recipients r 
        USE INDEX (index_recipients_on_campaign_resident_status)
        ON e.campaign_id = r.campaign_id 
        AND r.campaign_id IN (#{campaign_ids.join(", ")})
        AND e.resident_id = r.resident_id 
      WHERE e.campaign_id IN (#{campaign_ids.join(", ")})
      GROUP BY r.status;").each do |m|
     
      status = m.status.to_s.downcase
      
      if !["prospect_leased", "prospect_active", "prospect_dead", "resident_current", "resident_past", "resident_future", "resident_notice"].include?(status)
        status = "n/a"
      end

      if hash[status]
        hash[status] << m
      else
        hash[status] = [m]
      end
    end

    hash.keys.each do |status|
      metric = { "status" => status }

      hash[status].each do |m|
        m.attributes.keys.each do |k|
          next if k == "status"
          metric[k] = metric[k].to_i + m.send(k).to_i
          @status_total[k] = @status_total[k].to_i + m.send(k).to_i
        end
      end

      @status_metrics << metric
    end
  end
  
  def spam_watch_by_audience
    campaign_ids = @campaign.multi_sends.collect{|c| c.id }
    pp "campaign_ids: ", campaign_ids
    
    @audience_metrics = []
    @audience_total = {}
    
    Recipient.find_by_sql("SELECT r.audience_id,
        count(if(e.type='SendEvent', 1, NULL)) AS total_sends,
        count(if(e.type='LinkClickEvent', 1, NULL)) AS total_clicks,
        count(if(e.type='UnsubscribeClickEvent', 1, NULL)) AS total_unsubscribes,
        count(if(e.type='ComplaintEvent', 1, NULL)) AS total_complaints
      FROM events e
      INNER JOIN recipients r 
        USE INDEX (index_recipients_on_campaign_resident_audience)
        ON e.campaign_id = r.campaign_id 
        AND r.campaign_id IN (#{campaign_ids.join(", ")})
        AND e.resident_id = r.resident_id
      WHERE e.campaign_id IN (#{campaign_ids.join(", ")})
      GROUP BY r.audience_id;").each do |m|
     
      metric = {"audience_id" => m.audience_id}
      
      m.attributes.keys.each do |k|
        next if k == "audience_id"
        metric[k] = metric[k].to_i + m.send(k).to_i
        @audience_total[k] = @audience_total[k].to_i + m.send(k).to_i
      end
      
      @audience_metrics << metric
    end
    
    # convert audience_id to name
    Audience.includes(:property, :campaign).where(:id => @audience_metrics.collect{|m| m["audience_id"]}).each do |aud|
      @audience_metrics.detect{|m| m["audience_id"] == aud.id }["audience_name"] = aud.long_name
    end
  end
  
  def export_spam_watch
    deployment_time = @campaign.sent_at
    
    if params[:type] == "status"
      spam_watch_by_status
    
      csv_string = CSV.generate() do |csv|
        csv << [
          "Property Name", "Campaign Name", "Deployment Time",
          "Status", "# Sent", "# Clicks", "Clicks %", 
          "# Unsubscribed", "Unsubscribed %", 
          "# Complaints", "Complaints %", "Spam Index"
        ]

        @status_metrics.each do |m|
          csv << [
            @campaign.property.name,
            @campaign.annotation,
            deployment_time,
            m["status"],
            m["total_sends"],
            m["total_clicks"],
            conversion(m["total_clicks"], m["total_sends"]),
            m["total_unsubscribes"],
            conversion(m["total_unsubscribes"], m["total_sends"]),
            m["total_complaints"],
            conversion(m["total_complaints"], m["total_sends"]),
            conversion(m["total_unsubscribes"] - m["total_clicks"], m["total_clicks"])
          ]
        end

        csv << [
          "Total", nil, nil, nil, nil,
          @status_total["total_sends"],
          @status_total["total_clicks"],
          conversion(@status_total["total_clicks"], @status_total["total_sends"]),
          @status_total["total_unsubscribes"],
          conversion(@status_total["total_unsubscribes"], @status_total["total_sends"]),
          @status_total["total_complaints"],
          conversion(@status_total["total_complaints"], @status_total["total_sends"]),
          conversion(@status_total["total_unsubscribes"] - @status_total["total_clicks"], @status_total["total_clicks"])
        ]
      end
    
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@campaign.annotation.gsub(" ","")}_SpamWatchByStatus_#{Date.today.strftime('%m_%d_%Y')}.csv")
      
    elsif params[:type] == "audience"
      spam_watch_by_audience
    
      csv_string = CSV.generate() do |csv|
        csv << [
          "Property Name", "Campaign Name", "Deployment Time",
          "Lead Group", "# Sent", "# Clicks", "Clicks %", 
          "# Unsubscribed", "Unsubscribed %", 
          "# Complaints", "Complaints %", "Spam Index"
        ]

        @audience_metrics.each do |m|
          csv << [
            @campaign.property.name,
            @campaign.annotation,
            deployment_time,
            m["audience_name"] || "N/A",
            m["total_sends"],
            m["total_clicks"],
            conversion(m["total_clicks"], m["total_sends"]),
            m["total_unsubscribes"],
            conversion(m["total_unsubscribes"], m["total_sends"]),
            m["total_complaints"],
            conversion(m["total_complaints"], m["total_sends"]),
            conversion(m["total_unsubscribes"] - m["total_clicks"], m["total_clicks"])
          ]
        end

        csv << [
          "Total", nil, nil, nil, nil,
          @audience_total["total_sends"],
          @audience_total["total_clicks"],
          conversion(@audience_total["total_clicks"], @audience_total["total_sends"]),
          @audience_total["total_unsubscribes"],
          conversion(@audience_total["total_unsubscribes"], @audience_total["total_sends"]),
          @audience_total["total_complaints"],
          conversion(@audience_total["total_complaints"], @audience_total["total_sends"]),
          conversion(@audience_total["total_unsubscribes"] - @audience_total["total_clicks"], @audience_total["total_clicks"])
        ]
      end
    
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@campaign.annotation.gsub(" ","")}_SpamWatchByLeadGroup_#{Date.today.strftime('%m_%d_%Y')}.csv")
    end
  end
  
  def generate_spam_watch
    @campaign.multi_sends.each do |c|
      Resque.enqueue(RecipientImporter, c.id)
      session["generating_spam_watch_#{c.id}"] = 1
    end
    
    render :json => {:success => true}
  end
  
  def send_summary
    start_at = params[:range].first.to_time.in_time_zone.beginning_of_day
    end_at = params[:range].last.to_time.in_time_zone.end_of_day
    
    @all_properties = Property.all.collect{|p| p }
    
    property_ids = @all_properties.collect{|p| p.id }
    
    @all_audiences = Audience.where(:property_id => property_ids).includes(:campaign).all
    
    @nlt_campaigns = Campaign.unscoped.where(:property_id => property_ids).where("root_id IS NULL AND type IN ('NewsletterCampaign', 'NewsletterRescheduleCampaign') AND 
      published_at #{(start_at..end_at).to_s(:db)} AND sends_count > 0 AND deleted_at IS NULL").order("published_at desc").all
      
    root_va_ids = Campaign.where(:root_id => @nlt_campaigns.collect{|c| [c.id, c.group_id] }.flatten.compact.uniq, :parent_id => nil).collect{|c| [c.root_id, c.id] }
    
    # build newsletter hylet dict
    @nlt_dict = {}
    
    NewsletterHylet.where(:campaign_id => root_va_ids.collect{|r| r[1] }.uniq ).all.each do |hylet|
      root_id = root_va_ids.detect{|r| r[1] == hylet.campaign_id}[0]
      
      @nlt_dict[root_id] = hylet
    end
    
    # build annotation dict
    @annotation_dict = {}
    
    @nlt_campaigns.each do |c|
      @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank? # if root, don't use the .annotation method
    end
    
    reschedule_ids = @nlt_campaigns.collect{|c| c.group_id if c.group_id }.compact
    
    if !reschedule_ids.empty?
      Campaign.where(:id => reschedule_ids).each do |c|
        @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank?
      end
    end
  end
  
  def export_send_summary
    send_summary
    
    page_dict = {}
  	@all_properties.each do |p|
  	  page_dict[p.id] = p.name
    end
    
    csv_string = CSV.generate() do |csv|
      csv << ["Property Name", "Date & Time", "Campaign Name", "Subject", "Sends",
              "Unique Opens", "Unique Opens %", "Clicks", "Clicks %", "Unique Clicks", "Unique Clicks %",
              "Unsubscribes", "Unsubscribe %", "Spam Index", "Bounce", "Bounce %", "Complaints", "Complaints %", "# Lead Groups"]

      total_sends = 0
      total_opens = 0
      total_clicks = 0
      total_unique_clicks = 0
      total_unsubscribes = 0
      total_bounces = 0
      total_complaints = 0
      
      @nlt_campaigns.each do |campaign|
        root_id = campaign.kind_of?(NewsletterRescheduleCampaign) ? campaign.group_id : campaign.id
        nlt_hylet = @nlt_dict[root_id]
        
        if nlt_hylet
          schedule = nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == campaign.published_at.to_i }
          
          if schedule && !schedule["subject"].blank?
            subject = schedule["subject"].values.first
          else
            subject = nlt_hylet.subject
          end
          
        else
          subject = "<deleted>"
        end
        
        total_sends += campaign.sends_count
        total_opens += campaign.unique_opens_count
        total_clicks += campaign.clicks_count
        total_unique_clicks += campaign.unique_clicks_count
        total_unsubscribes += campaign.unsubscribes_count
        total_bounces += campaign.bounces_count
        total_complaints += campaign.complaints_count
        
        subjects = [subject]
        schedules = [campaign.published_at.to_s(:csv_time)]
        
        if nlt_hylet && !nlt_hylet.schedules.empty?
          nlt_hylet.schedules.each do |s|
            next if s["timestamp"].to_i == campaign.published_at.to_i || campaign.kind_of?(NewsletterRescheduleCampaign)
            schedules << Time.at(s["timestamp"].to_i).to_s(:csv_time)
            s["subject"].values.each do |v|
              subjects << v
            end
          end
        end
        
        csv << [page_dict[campaign.property_id], schedules.join("; "), @annotation_dict[root_id], subjects.join("; "),
                campaign.sends_count, campaign.unique_opens_count,
                conversion(campaign.unique_opens_count, campaign.sends_count),
                campaign.clicks_count, conversion(campaign.clicks_count, campaign.sends_count),
                campaign.unique_clicks_count, conversion(campaign.unique_clicks_count, campaign.sends_count),
                campaign.unsubscribes_count, conversion(campaign.unsubscribes_count, campaign.sends_count),
                conversion(campaign.unsubscribes_count - campaign.clicks_count, campaign.clicks_count),
                campaign.bounces_count, conversion(campaign.bounces_count, campaign.sends_count),
                campaign.complaints_count, conversion(campaign.complaints_count, campaign.sends_count),
                nlt_hylet ? nlt_hylet.audience_ids.length : nil]
      end
      
      csv << ["Total", nil, nil, nil, total_sends, total_opens, conversion(total_opens, total_sends), 
              total_clicks, conversion(total_clicks, total_sends), total_unique_clicks, conversion(total_unique_clicks, total_sends),
              total_unsubscribes, conversion(total_unsubscribes, total_sends),
              conversion(total_unsubscribes - total_clicks, total_clicks),
              total_bounces, conversion(total_bounces, total_sends), total_complaints, conversion(total_complaints, total_sends), nil]
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@property.name.gsub(" ","")}_EmailsSent_#{Date.today.strftime('%m_%d_%Y')}.csv")
  end
  
  def send_schedule
    @all_properties = Property.all.collect{|p| p }
    
    property_ids = @all_properties.collect{|p| p.id }

    @all_audiences = Audience.where(:property_id => property_ids).includes(:campaign).all

    @nlt_campaigns = Campaign.unscoped.where(:property_id => property_ids, :deleted_at => nil)
                      .select('campaigns.*, actions.execute_at')
                      .joins("INNER JOIN actions ON actions.subject_id = campaigns.id")
                      .order("execute_at asc")
                      
    if action_name != "export_send_schedule"
      @nlt_campaigns = @nlt_campaigns.paginate(:page => params[:page], :per_page => 20)
    end
    
    root_va_ids = Campaign.where(:root_id => @nlt_campaigns.collect{|c| [c.id, c.group_id] }.flatten.compact.uniq, :parent_id => nil).collect{|c| [c.root_id, c.id] }
    
    # build newsletter hylet dict
    @nlt_dict = {}
    
    NewsletterHylet.where(:campaign_id => root_va_ids.collect{|r| r[1] }.uniq ).all.each do |hylet|
      root_id = root_va_ids.detect{|r| r[1] == hylet.campaign_id}[0]
      
      @nlt_dict[root_id] = hylet
    end
    
    # build annotation dict
    @annotation_dict = {}
    
    @nlt_campaigns.each do |c|
      @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank? # if root, don't use the .annotation method
    end
    
    reschedule_ids = @nlt_campaigns.collect{|c| c.group_id if c.group_id }.compact
    
    if !reschedule_ids.empty?
      Campaign.where(:id => reschedule_ids).each do |c|
        @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank?
      end
    end
  end
  
  def export_send_schedule
    send_schedule

    page_dict = {}
  	@all_properties.each do |p|
  	  page_dict[p.id] = p.name
    end

  	audience_dict = {}
  	@all_audiences.each do |a|
  	  audience_dict[a.id] = a
    end

    csv_string = CSV.generate() do |csv|
      csv << ["Send At", "Property Name", "Campaign Name", "Subject", "From", "Audience"]


      @nlt_campaigns.each do |campaign|
        root_id = campaign.kind_of?(NewsletterRescheduleCampaign) ? campaign.group_id : campaign.id
        nlt_hylet = @nlt_dict[root_id]

        if nlt_hylet
          schedule = nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == campaign.execute_at.to_i }

          if schedule && !schedule["subject"].blank?
            subject = schedule["subject"].values.first
          else
            subject = nlt_hylet.subject
          end

          audiences = nlt_hylet.audience_ids.collect{|id| audience_dict[id.to_i] }.compact

        else
          audiences = []
          subject = "<deleted>"
        end

        csv << [ campaign.execute_at.in_time_zone.to_s(:csv_time),
                  page_dict[campaign.property_id], @annotation_dict[root_id], subject, nlt_hylet.from,
                  audiences.collect{|a| "#{page_dict[a.property_id]} #{a.name}" }.join("; ")]
      end

    end

    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@property.name.gsub(" ","")}_EmailsScheduled_#{Date.today.strftime('%m_%d_%Y')}.csv")
  end
  
  def recent_send
    
    @all_properties = Property.all.collect{|p| p }
    
    property_ids = @all_properties.collect{|p| p.id }
    
    @all_audiences = Audience.where(:property_id => property_ids).includes(:campaign).all
    
    @nlt_campaigns = {}
    @scheduled_campaigns = {}
    
    campaign_id_and_group_id = []
    
    Campaign.unscoped.find_by_sql("
      SELECT a.* FROM campaigns a
      INNER JOIN (
        SELECT max(published_at) as mx, property_id FROM campaigns
        WHERE property_id IN (#{property_ids.join(', ')}) AND root_id IS NULL AND type IN ('NewsletterCampaign', 'NewsletterRescheduleCampaign') AND 
         sends_count > 0 AND deleted_at IS NULL
        GROUP BY property_id
      ) b ON a.property_id = b.property_id AND a.published_at = b.mx WHERE a.sends_count > 0").each do |c|
      
        @nlt_campaigns[c.property_id] = c
        campaign_id_and_group_id << c.id
        campaign_id_and_group_id << c.group_id
    end
    
    # actions contains all newsletter root
    # must be ordered by execute_at asc
    
    Campaign.unscoped.find_by_sql("
      SELECT a.*,  b.execute_at FROM campaigns a
      INNER JOIN actions b ON b.subject_id = a.id AND b.subject_type = 'Campaign'
      WHERE property_id IN (#{property_ids.join(', ')})
      ORDER BY b.execute_at ASC").each do |c|
        
        # collect only the next schedule campaign
        @scheduled_campaigns[c.property_id] = c if !@scheduled_campaigns[c.property_id]
        
        campaign_id_and_group_id << c.id
        campaign_id_and_group_id << c.group_id
    end
      
    root_va_ids = Campaign.where(:root_id => campaign_id_and_group_id.compact.uniq, :parent_id => nil).collect{|c| [c.root_id, c.id] }
    
    # build newsletter hylet dict
    @nlt_dict = {}
    
    NewsletterHylet.where(:campaign_id => root_va_ids.collect{|r| r[1] }.uniq ).includes(:campaign).all.each do |hylet|
      root_id = root_va_ids.detect{|r| r[1] == hylet.campaign_id }[0]
      
      @nlt_dict[root_id] = hylet
    end
    
    # build annotation dict
    @annotation_dict = {}
    
    @nlt_campaigns.values.each do |c|
      @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank? # if root, don't use the .annotation method
    end
    
    @scheduled_campaigns.values.each do |c|
      @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank? # if root, don't use the .annotation method
    end
    
    reschedule_ids = @nlt_campaigns.values.collect{|c| c.group_id if c.group_id }.compact
    
    if !reschedule_ids.empty?
      Campaign.where(:id => reschedule_ids).each do |c|
        @annotation_dict[c.id] = c["annotation"] if !c["annotation"].blank?
      end
    end
  end
  
  def export_recent_send
    recent_send

    csv_string = CSV.generate() do |csv|
      csv << [
        "Property Name",
        "Last Email Sent",
        "# Days Since Last Email",
        "Campaign Name",
        "Subject",
        "# Recipients",
        "Next Scheduled Deployment Date",
        "Next Scheduled Campaign Name",
        "Next Scheduled Subject"
      ]

      Property.all.sort{|a, b| a.sort_name.to_s <=> b.sort_name.to_s }.each do |prop|
        campaign = @nlt_campaigns[prop.property_id]
        scheduled_campaign = @scheduled_campaigns[prop.property_id]
        
        arr = [
          prop.name
        ]
        
        if campaign
          root_id = campaign.kind_of?(NewsletterRescheduleCampaign) ? campaign.group_id : campaign.id
          nlt_hylet = @nlt_dict[root_id]

          if nlt_hylet
            schedule = nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == campaign.published_at.to_i }

            if schedule && !schedule["subject"].blank?
              subject = schedule["subject"].values.first
            else
              subject = nlt_hylet.subject
            end

          else
            subject = "<deleted>"
          end
          
          arr += [
            campaign.published_at.to_s(:csv_time),
            (Time.now.to_date - campaign.published_at.to_date).to_i,
            @annotation_dict[root_id], 
            subject,
            campaign.sends_count
          ]
          
        else
          arr += ["N/A", "N/A", "N/A", "N/A", "N/A"]
                  
        end
        
        if scheduled_campaign
          root_id = scheduled_campaign.id
          nlt_hylet = @nlt_dict[root_id]

          if nlt_hylet
            schedule = nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == scheduled_campaign.execute_at.to_i }

            if schedule && !schedule["subject"].blank?
              subject = schedule["subject"].values.first
            else
              subject = nlt_hylet.subject
            end

          else
            subject = "<deleted>"
          end
          
          arr += [ 
            scheduled_campaign.execute_at.to_s(:csv_time),
            @annotation_dict[root_id], 
            subject
          ]
        else
          arr += ["N/A", "N/A", "N/A"]
        end
        
        csv << arr
      end
    end

    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@property.name.gsub(" ","")}_MostRecentEmail_#{Date.today.strftime('%m_%d_%Y')}.csv")
  end
  
  #exports
  
  def export_email_stats
  
    if EmailStatExporter.sendible?
      csv_string, file_name = EmailStatExporter.init(@property, @campaign, params).generate_csv

      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
    end
  end
  
  def export_subscribers
    exporter = SubscriberExporter.init(@property, @campaign, params)
    
    respond_to do |format|
      format.js {
        if params[:recipient]
          Resque.enqueue(SubscriberExporter, @property.id, @campaign.id, params)
          
        else
          @sendible = exporter.sendible?
        end
      }
      format.html {
        csv_string, file_name = exporter.generate_csv

        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
      }
    end
  end
   
  protected
  
    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
      @property = @campaign.property
      
      Time.zone = @property.setting.time_zone
      
      @campaign.tmp_timestamp = params[:timestamp] if @campaign
      
      case action_name
        when "create"
          authorize! :cud, Campaign
          
        when "edit", "update", "destroy"
          authorize! :cud, @campaign
          
        else
          authorize! :read, @campaign
      end
    end
    
    def set_filter_params
      if params[:range].blank?
        if !cookies[:report_range].blank?
          start_at, end_at = cookies[:report_range].split("_", 2)
          params[:range] = [Time.at(start_at.to_i), Time.at(end_at.to_i)]
        else
          params[:range] = [Time.zone.today - 30.days, Time.zone.today - 1.day]
        end
        
        
      elsif params[:range].kind_of?(Array)
        params[:range] = [Date.parse(params[:range].first), Date.parse(params[:range].last)]
        
      end
      
      cookies[:report_range] = {
        :value => "#{params[:range][0].to_time.to_i}_#{params[:range][1].to_time.to_i}",
        :expires => Time.now + 3.hours,
        :path => "/",
        :domain => ".#{HOST.split(':').first}"
      } 
      
      params[:range][0] = params[:range][0].end_of_day
      params[:range][1] = params[:range][1].end_of_day
      
      if params[:report_type].blank?
        params[:report_type] = "daily"
      end
      
      if params[:channel].blank?
        params[:channel] = "all"
      end

    end
    
    def set_page_title
      @page_title = "CRM - #{@campaign.annotation} - Reports"
    end
    
    def conversion(num, total)
      (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
    end
    
    def channel_condition(id)
      if params[:channel] == "all"
        "#{id} IN (#{@campaign.all_variates.collect{|v| v.id}.join(', ')}) AND"
      else
        "#{id} IN (#{@campaign.all_variates.collect{|v| v.id if v.channel == params[:channel].to_i }.compact.join(', ')}) AND"
      end
    end
    
    def dashboard_metrics
      
      start_at = params[:range].first.to_time.in_time_zone.beginning_of_day + UtcOffset::DST_HOUR
      end_at = params[:range].last.to_time.in_time_zone.end_of_day + UtcOffset::DST_HOUR
      
      #note: start_at, end_at does not take any effect if newsletter campaign
      if [NewsletterCampaign].any?{|clzz| @campaign.kind_of?(clzz) }
        
        @link_clicks = []
        @opens_by_browser = []
        @opens_by_os = []
        @opens_by_country = []
        
        vars = [@link_clicks, @opens_by_browser, @opens_by_os, @opens_by_country]
        
        queries = [
          variation_metrics(start_at, end_at).where("type IN ('LinkClickVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text"),
          variation_metrics(start_at, end_at).where("type IN ('BrowserVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text"),
          variation_metrics(start_at, end_at).where("type IN ('OsVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text"),
          variation_metrics(start_at, end_at).where("type IN ('CountryVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text")
        ]
        
        queries.each_with_index do |query, index|
          metrics = query.all.collect{|m| m }

          total_events = metrics.sum{|m| m.total_events.to_i}

          metrics.each do |m|
            vars[index] << {:name => m.text, :count => m.total_events.to_i, :conversion => conversion(m.total_events, total_events)}
          end
          
          vars[index].sort!{|a, b| b[:count] <=> a[:count]}
          
          #top 10 metrics
          if vars[index].length > 8
            others = vars[index].slice!(8, vars[index].length)
    
            if others.kind_of?(Array)
              vars[index] << {:name => "others", :count => others.sum{|m| m[:count]}, :conversion => others.sum{|m| m[:conversion]}.round(2) }
            end
          end
        end
      end
      
    end
    
    def variation_metrics(start_at, end_at)
      if @campaign.kind_of?(NewsletterCampaign)
        if @campaign.nlt_clzz?
          VariationMetric.where(:property_id => @campaign.property.id).where("#{channel_condition('variation_id').gsub('AND', '')}")

        else
          @campaign.variation_metrics.where("#{channel_condition('variation_id').gsub('AND', '')}")
        end
      end
    end
    

end
