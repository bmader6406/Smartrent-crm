class  CampaignVariationMetric < VariationMetric
  def self.campaign_metrics(campaign, range, tz = "UTC", channel_condition)

    start_at = range.first.to_time.in_time_zone(tz).beginning_of_day + UtcOffset::DST_HOUR
    end_at = range.last.to_time.in_time_zone(tz).end_of_day + UtcOffset::DST_HOUR
      
    days = ((end_at.to_i - start_at.to_i)/(86400.0) + 0.2).round

    categories = []
    series = {}
    
    total_entries = {"all" => 0}
    total_sessions = {"all" => 0}
    
    empty = []
    zero = []
    position = 0
    dict = {}
    
    days.times.each do |i|
      empty << nil
      zero << 0
      categories << (start_at + i.days).in_time_zone(tz).strftime('%b %e')
    end
	  
    if channel_condition
      metrics = campaign.variation_metrics.unscoped.where("campaign_id = #{campaign.id} AND #{channel_condition} created_at #{(start_at..end_at).to_s(:db)} AND
        type IN ('CampaignVariationMetric')").select("campaign_id, variation_id, sum(entries_count) as total_entries, sum(sessions_count) as total_sessions,
          created_at").group("variation_id, created_at").order('created_at asc')
        
    else
      metrics = VariationMetric.unscoped.where("property_id = #{campaign.property_id} AND created_at #{(start_at..end_at).to_s(:db)} AND
        type IN ('CampaignVariationMetric')").select("campaign_id, variation_id, sum(entries_count) as total_entries, sum(sessions_count) as total_sessions,
          created_at").group("campaign_id, created_at").order('created_at asc')
        
    end
    
    if channel_condition
      
      campaign.dict_variates["all"].each do |v|
    		dict["#{v.id}"] = v.name
    	end
    
    else
      
      VariationMetric.unscoped.where("variation_metrics.property_id = #{campaign.property_id} AND variation_metrics.created_at #{(start_at..end_at).to_s(:db)} AND
        variation_metrics.type IN ('CampaignVariationMetric')").select("campaign_id, annotation").group("campaign_id").joins("INNER JOIN campaigns ON campaigns.id = campaign_id").each do |row|
        
        dict["#{row.campaign_id}"] = row.annotation
        
      end
      
    end
    
    dict.keys.each do |k|
      series["#{k}_entries_count"] = {:data => empty.clone, :change => 0, :name => dict[k]}
      series["#{k}_visitors_count"] = {:data => empty.clone, :change => 0, :name => dict[k]}
      series["#{k}_avg_conversion"] = {:data => zero.clone, :change => 0, :name => dict[k]}
      total_entries["#{k}"] = 0
      total_sessions["#{k}"] = 0
    end
    
    metrics.each_with_index do |metric, index|
      
      
      if series["#{metric.variation_id}_entries_count"] || series["#{metric.campaign_id}_entries_count"]
        
        position =  ((metric.created_at - start_at)/(86400.0) + 0.2).round - 1
        
        key = channel_condition ? metric.variation_id : metric.campaign_id
        
        total_entries["#{key}"] += metric.total_entries.to_i
        total_sessions["#{key}"] += metric.total_sessions.to_i
        
        total_entries["all"] +=  metric.total_entries.to_i
        total_sessions["all"] += metric.total_sessions.to_i

        series["#{key}_entries_count"][:data][position] = total_entries["#{key}"]
        series["#{key}_visitors_count"][:data][position] = total_sessions["#{key}"]

        series["#{key}_avg_conversion"][:data][position] = conversion( total_entries["#{key}"], total_sessions["#{key}"])

      end

    end
    
    #populate null field & "the rest" serie, all conversion chart
    all_entries = zero.clone
    all_sessions = zero.clone
    all_conversions = []
    
    series.keys.each do |k|
      start = series[k][:data][0].to_i
      
      series[k][:data].each_with_index do |v, index|
        if !v || v.zero?
          series[k][:data][index] = start
        else
          start = v
        end
        
        #pp k, index, v
        
        all_entries[index] += series[k][:data][index] if all_entries[index] && k.include?('entries_count')
        all_sessions[index] += series[k][:data][index] if all_sessions[index] && k.include?('visitors_count')
      end
      
      series[k][:change] = total_entries[k.split("_").first] if k.include?('entries_count')
      series[k][:change] = total_sessions[k.split("_").first] if k.include?('visitors_count')
    end
    
    dict.keys.each do |k|
      series["#{k}_avg_conversion"][:change] = conversion(series["#{k}_entries_count"][:change], series["#{k}_visitors_count"][:change])
    end
    
    top_series = {}
    
    ["entries_count", "visitors_count", "avg_conversion"].each do |type|
      
      keys = dict.keys.sort{|k2, k1| series["#{k1}_#{type}"][:change] <=> series["#{k2}_#{type}"][:change]}.collect{|k| "#{k}_#{type}"}
      
      if keys.length > 5
        top4 = keys.slice(0, 4)
        rest = keys.slice(4, keys.length)
        
        #added "the rest" serie
        data = []
        change = 0
        
        rest.each_with_index do |key, index|
          change += series[key][:change]
          
          if index == 0
            data = series[key][:data]
          else
            data = data.zip(series[key][:data]).map {|a| a.inject(:+)}
          end
        end
        
        series["rest_#{type}"] = {:data => data, :change => change, :name => "The Rest"}

        top_series[type] = top4 + ["rest_#{type}"]
        
      else
        top_series[type] = keys
      end
      
    end
    
    #all conversion serie
    all_sessions.each_with_index do |sessions_count, index|
      all_conversions << conversion(all_entries[index], sessions_count)
    end
    
    series["all_conversions"] = {:data => all_conversions, :change => (all_conversions.last.to_i - all_conversions.first.to_i), :name => "Conversion"}
    
    return {:categories => categories, :series => series, :total_entries => total_entries, :total_sessions => total_sessions, :top_series => top_series}
  end
  
  
    
  def self.tag_metrics(campaign, range, tz = "UTC", channel_condition, tag)
    
    start_at = range.first.to_time.in_time_zone(tz).beginning_of_day + UtcOffset::DST_HOUR
    end_at = range.last.to_time.in_time_zone(tz).end_of_day + UtcOffset::DST_HOUR
      
    days = ((end_at.to_i - start_at.to_i)/(86400.0) + 0.2).round
    
    categories = []
    series = {}
    
    total_entries = {}
    total_sessions = {}
    
    empty = []
    zero = []
    position = 0
    dict = {}
    
    days.times.each do |i|
      empty << nil
      zero << 0
      categories << (start_at + i.days).in_time_zone(tz).strftime('%b %e')
    end
    
    #filter by tag A, B or B, C or C, D
    app_data = []
    tag_condition = ""
    
    if tag.blank?
      app_data = ["app_data_a", "app_data_b"]
      
    else
      tags = tag.to_s.split(".")
      
      case tags.length
        when 1
          tag_condition = "AND app_data_a = '#{tags[0]}'"
          app_data = ["app_data_b", "app_data_c"]
        when 2
          tag_condition = "AND app_data_a = '#{tags[0]}' AND app_data_b = '#{tags[1]}'"
          app_data = ["app_data_c", "app_data_d"]
      end
    end
    
    #create dict
    if tag_condition.blank?
      dict = {"organic" => "Organic", "organic.unknown" => "Unknown"}
    else
      dict = {}
    end
    
    
    if channel_condition
      metrics = campaign.multi_variation_metrics.unscoped.where("#{channel_condition} created_at #{(start_at..end_at).to_s(:db)} #{tag_condition}")
    else
      metrics = MultiVariationMetric.unscoped.where("property_id = #{campaign.property.id} AND created_at #{(start_at..end_at).to_s(:db)} #{tag_condition}")
    end
    
    metrics.select("#{app_data.collect{|ad| ad }.join(', ') }").group("#{app_data.collect{|ad| ad }.join(', ') }").each do |metric|

      if !metric.send(app_data[0]).blank?
        dict[metric.send(app_data[0])] = campaign.tag_name(app_data[0].gsub('app_data_', '').upcase, metric.send(app_data[0]))
        
        if !metric.send(app_data[1]).blank?
          dict["#{metric.send(app_data[0])}.#{metric.send(app_data[1])}"] = campaign.tag_name(app_data[1].gsub('app_data_', '').upcase, metric.send(app_data[1]))
        else
          dict["#{metric.send(app_data[0])}.unknown"] = "Unknown"
        end
        
      end
      
    end
    
    dict.keys.each do |k|
      series["#{k}_entries_count"] = {:data => empty.clone, :change => 0, :name => dict[k]}
      series["#{k}_visitors_count"] = {:data => empty.clone, :change => 0, :name => dict[k]}
      total_entries["#{k}"] = 0
      total_sessions["#{k}"] = 0
    end
    
    metrics.select("#{app_data.collect{|ad| ad }.join(', ') }, sum(entries_count) as total_entries,
      sum(sessions_count) as total_sessions, created_at").group("#{app_data.collect{|ad| ad }.join(', ') }, created_at").order('created_at asc').each do |metric|
      
      position =  ((metric.created_at - start_at)/(86400.0) + 0.2).round - 1
      
      keys = []
      
      if !metric.send(app_data[0]).blank?
        keys << metric.send(app_data[0])
        
        if !metric.send(app_data[1]).blank?
          keys << "#{metric.send(app_data[0])}.#{metric.send(app_data[1])}"
        else
          keys << "#{metric.send(app_data[0])}.unknown"
        end
        
      elsif tag_condition.blank?
        keys << "organic"
        keys << "organic.unknown"

      end
      
      keys.each do |key|
        if series["#{key}_entries_count"]
        
          total_entries["#{key}"] += metric.total_entries.to_i
          total_sessions["#{key}"] += metric.total_sessions.to_i

          series["#{key}_entries_count"][:data][position] = total_entries["#{key}"]
          series["#{key}_visitors_count"][:data][position] = total_sessions["#{key}"]
        
        end
      end
      
    end
    
    #populate null field & "the rest" serie
    series.keys.each do |k|
      start = series[k][:data][0].to_i
      
      series[k][:data].each_with_index do |v, index|
        if !v || v.zero?
          series[k][:data][index] = start
        else
          start = v
        end
        
      end

      series[k][:change] = total_entries[k.split("_").first] if k.include?('entries_count')
      series[k][:change] = total_sessions[k.split("_").first] if k.include?('visitors_count')
    end
    
    top_series = {}
    sub_keys = {}
    
    main_keys = dict.keys.collect{|k| k if !k.include?('.') }.compact
    main_keys.each do |tk|
      sub_keys[tk] = dict.keys.collect{|k| k if k.include?("#{tk}.") }.compact
    end
    
    # main_keys : ["organic", "c", "i", "s", "v"]
    # sub_keys: {"c"=>["c.in"],
    #  "i"=>["i.em", "i.tw"],
    #  "s"=>["s.bl", "s.e", "s.f", "s.in", "s.li", "s.tw"],
    #  "v"=>["v.or"]}
    
    main_keys = main_keys.sort{|a,b| b <=> a }
    
    if tag_condition.blank?
      main_keys.delete_if{|tk| tk == "organic"} #move organic to bottom
      main_keys << "organic"
    end
    
    main_keys.each do |tk|
      
      top_series[tk] = {}
      
      ["entries_count", "visitors_count"].each do |type|
      
        keys = sub_keys[tk].sort{|k2, k1| series["#{k1}_#{type}"][:change] <=> series["#{k2}_#{type}"][:change]}.collect{|k| "#{k}_#{type}"}

        if keys.length > 5
          top4 = keys.slice(0, 4)
          rest = keys.slice(4, keys.length)
        
          #added "the rest" serie
          data = []
          change = 0
        
          rest.each_with_index do |key, index|
            change += series[key][:change]
          
            if index == 0
              data = series[key][:data]
            else
              data = data.zip(series[key][:data]).map {|a| a.inject(:+)}
            end
          end
        
          series["rest_#{tk}_#{type}"] = {:data => data, :change => change, :name => "The Rest"}

          top_series[tk][type] = top4 + ["rest_#{tk}_#{type}"]
        
        else
          top_series[tk][type] = keys
        end
      
      end
    end
    
    return {:categories => categories, :series => series, :total_entries => total_entries,
        :total_sessions => total_sessions, :top_series => top_series, :main_keys => main_keys,
        :sub_keys => sub_keys, :main_key_type => app_data[0].gsub("app_data_", "").upcase}
          
  end  
  
end
