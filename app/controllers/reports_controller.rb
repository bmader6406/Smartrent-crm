class ReportsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_page_title
  
  def index
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_reports(params[:per_page])
      }
    end
  end
  
  def residents
    @property_dict = {}
    @unit_dict = {}
    
    exporter = ResidentExporter.init(params)
    
    page = (params[:page] || 1).to_i
    per_page = (params[:rp] || 15).to_i
    limit = page*per_page
    skip = limit - per_page
    
    @residents = WillPaginate::Collection.create(page, per_page, exporter.residents_count) do |pager|
      pager.replace exporter.residents_listing(limit, skip)
    end
    
    Property.where(:id => @residents.collect{|r| r["units"]["property_id"] }).each do |p|
      @property_dict[p.id.to_s] = p.name
    end
    
    Unit.where(:id => @residents.collect{|r| r["units"]["unit_id"] }).each do |u|
      @unit_dict[u.id.to_s] = u.code
    end
  end

  def export_residents
    exporter = ResidentExporter.init(params)

    respond_to do |format|
      format.js {
        if params[:recipient]
          Resque.enqueue(ResidentExporter, params)

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
  
  def metrics
    required = [
      "age",
      "age_range",
      "gender",
      "income_range",
      "units.annual_income",
      "units.household_size",
      "units.household_status",
      "units.minutes_to_work",
      "units.moving_from",
      "units.occupation_type",
      "units.pet_type",
      "units.transportation_to_work",
      "total_cars",
      "total_occupied_units",
      "total_pets",
      "total_residents",
      "total_residents_with_pets",
      "total_units"
    ]
    
    cond = {:property_id => params[:property_ids]}
    cond[:status] = params[:statuses] if !params[:statuses].blank?
    cond[:rental_type] = params[:rental_types] if !params[:rental_types].blank?
    
    if params[:type] == "summary"
      @metric = ResidentMetric.where(cond).select("type, sum(total) as total, dimension").group("type, dimension").group_by{|m| m.type }
      
      required.each do |type|
        @metric[type] = [] if !@metric[type]
      end
      
    elsif params[:type] == "comparison"        
      @comparison = [] #{:property_name => xx, :metrics => []}
      properties = Property.where(:id => params[:property_ids]).all
      
      property_metrics = ResidentMetric.where(cond).select("property_id, type, sum(total) as total, dimension").group("property_id, type, dimension").group_by{|m| m.property_id }
      
      property_metrics.keys.each do |k|
        metric = property_metrics[k].group_by{|m| m.type }
        required.each do |type|
          metric[type] = [] if !metric[type]
        end
        
        @comparison << { :property => properties.detect{|p| p.id == k.to_i }, :metric => metric }
      end
      
    end
  end
  
  def export_metrics
    metrics

    csv_string = CSV.generate() do |csv|
      
      if params[:type] == "summary"
        
        group_total = @metric["income_range"].sum{|m| m.total }
        csv << ["Annual Income", "#", "%"]
        @metric["income_range"].sort{|a, b| a.dimension.scan(/\d+/).first.to_i <=> b.dimension.scan(/\d+/).first.to_i }.each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        csv << []
        csv << []
        csv << [
          "Average (mean) household income",
          nil,
          avg(@metric["units.annual_income"].sum{|m| m.total*m.dimension.to_i }, @metric["units.annual_income"].sum{|m| m.total })
        ]
        
        
        group_total = @metric["units.occupation_type"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Occupations", "#", "%"]
        @metric["units.occupation_type"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["units.minutes_to_work"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Minutes To Work", "#", "%"]
        @metric["units.minutes_to_work"].sort{|a, b| a.dimension.scan(/\d+/).first.to_i <=> b.dimension.scan(/\d+/).first.to_i }.each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["age_range"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Age Range", "#", "%"]
        @metric["age_range"].sort{|a, b| a.dimension.scan(/\d+/).first.to_i <=> b.dimension.scan(/\d+/).first.to_i }.each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["units.household_status"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Occupant Status", "#", "%"]
        @metric["units.household_status"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["units.household_size"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Average Household Size", "#", "%"]
        @metric["units.household_size"].sort{|a, b| a.dimension.scan(/\d+/).first.to_i <=> b.dimension.scan(/\d+/).first.to_i }.each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        total_cars = @metric["total_cars"].sum{|m| m.total }
        total_residents = @metric["total_residents"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Number Of Cars", "#", "Ratio"]
        csv << ["Total", total_cars, "#{conversion(total_cars, total_residents)}%"]
        
        
        group_total = @metric["units.pet_type"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Number Of Residents With Pets", "#", "%"]
        @metric["units.pet_type"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total Number Residents With Pets", nil, @metric["total_residents_with_pets"].sum{|m| m.total }]
        csv << ["Total Number Of Pets", nil, @metric["total_pets"].sum{|m| m.total }]
        
        
        group_total = @metric["gender"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Gender", "#", "%"]
        @metric["gender"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["units.transportation_to_work"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Transportation", "#", "%"]
        @metric["units.transportation_to_work"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
        
        group_total = @metric["units.moving_from"].sum{|m| m.total }
        csv << []
        csv << []
        csv << ["Where Moved From", "#", "%"]
        @metric["units.moving_from"].each do |m|
          csv << [m.dimension, m.total, "#{conversion(m.total, group_total)}%"]
        end
        csv << ["Total", nil, group_total]
        
      elsif params[:type] == "comparison"
        csv << [
          "Property Name",
          "Average - # of Total Units",
          "Average - # of Occupied Units ",
          "Average - Household Income ",
          "Average - Income for MI Last 90 Days",
          "Average - Household Size",
          "Average - Commute time to work (min)",
          "Average - Age ",
          "Average - # of Cars/Unit",
          "Top Two Household Status",
          "% of Males",
          "% of Females ",
          "% Pets Per Unit",
          "# of Residents with Pets",
          "Top Two Modes of Transportation to Work",
          "Top Two Previous Housing"
        ]
        
        @comparison.each do |hash| 

          metric = hash[:metric]
          total_units = metric["total_units"].sum{|m| m.total }
          total_occupied_units = metric["total_occupied_units"].sum{|m| m.total }

          csv << [
            hash[:property].name,
            total_units,
            total_occupied_units,
            avg(metric["units.annual_income"].sum{|m| m.total*m.dimension.to_i }, metric["units.annual_income"].sum{|m| m.total }),
            "N/A",
            avg(metric["units.household_size"].sum{|m| m.total*m.dimension.to_i }, metric["units.household_size"].sum{|m| m.total }),
            avg(metric["units.minutes_to_work"].sum{|m| m.total*m.dimension.scan(/\d+/).sum{|n| n.to_i } }, metric["units.minutes_to_work"].sum{|m| m.total }),
            avg(metric["age"].sum{|m| m.total*m.dimension.to_i }, metric["age"].sum{|m| m.total }),
            avg(metric["total_cars"].sum{|m| m.total }, total_occupied_units),
            metric["units.household_status"].sort{|a, b| b.total <=> a.total }[0..1].collect{|m|
              "#{m.dimension} - #{conversion(m.total, metric["units.household_status"].sum{|m| m.total }).to_i}%"
            }.join("        "),
            conversion(metric["gender"].sum{|m| m.dimension == "Male" ? m.total : 0 }, metric["gender"].sum{|m| m.total}),
            conversion(metric["gender"].sum{|m| m.dimension == "Female" ? m.total : 0 }, metric["gender"].sum{|m| m.total}),
            conversion(metric["total_pets"].sum{|m| m.total }, total_occupied_units),
            metric["total_residents_with_pets"].sum{|m| m.total },
            metric["units.transportation_to_work"].sort{|a, b| b.total <=> a.total }[0..1].collect{|m|
              "#{m.dimension} - #{conversion(m.total, metric["units.transportation_to_work"].sum{|m| m.total }).to_i}%"
            }.join("        "),
            metric["units.moving_from"].sort{|a, b| b.total <=> a.total }[0..1].collect{|m|
              "#{m.dimension} - #{conversion(m.total, metric["units.moving_from"].sum{|m| m.total }).to_i}%"
            }.join("        ")
          ]

        end
      end
      
      
    end

    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{params[:type]}Report_#{Date.today.strftime('%m_%d_%Y')}.csv")
  end
  
  private
    
    def set_property
      if params[:property_id]
        @property = current_user.managed_properties.find(params[:property_id])
      
        Time.zone = @property.setting.time_zone
      end
    end

    def set_page_title
      if @property
        @page_title = "CRM - #{@property.name} - Reports" 
      else
        @page_title = "CRM - Reports" 
      end
    end
    
    def filter_reports(per_page = 15)
      arr = []
      hash = {}
      
      ["name"].each do |k|
        next if params[k].blank?
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @reports = @property.reports.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page)
    end
end