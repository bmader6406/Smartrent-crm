class MetricGenerator
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_medium
  end

  def self.perform(etime = Time.now.utc.to_i)
    begin
      time = Time.at(etime).utc
      time = time - time.min.minutes - time.sec.seconds #end of time-zone day
      start_at = time - 1.day
      end_at = time - 1.second

      midnight_time_zones = UtcOffset.midnight_time_zones(time.hour)
    
      PropertySetting.where("time_zone IN (?)", midnight_time_zones).includes(:property).each do |setting|
        next if !setting.property || !setting.property.is_crm?
          
        Time.zone = setting.time_zone
        
        if setting.property
          pp "Calculating... #{setting.property.name}"
          calculate(setting.property)
        else
          pp "Property (#{setting.property_id}) Not Found"
        end
      end
    
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"
    
      Resque.enqueue(SystemMessageMailer, "[MetricGenerator] FAILURE", error_details)
    end
  
  end

  def self.calculate(property)
    # summary reports
    ResidentMetric.where(:property_id => property.id).delete_all
    
    ["units.occupation_type", "units.minutes_to_work",
      "units.household_status", "units.household_size", 
      "gender", "units.transportation_to_work", "units.moving_from"].each do |field|
        
        count_by(property, field).each do |hash|
          ResidentMetric.create({
            :property_id => property.id,
            :type => field,
            :status => hash["_id"]["status"],
            :rental_type => hash["_id"]["rental_type"],
            :dimension => hash["_id"]["dimension"],
            :total => hash["count"]
          })
        end
    end
    
    
    income_range = [
      (0..15000),
      (15001..25000),
      (25001..40000),
      (40001..55000),
      (55001..70000),
      (70001..85000),
      (85001..100000),
      (100001..115000),
      (115001..130000),
      (130001..150000),
      (150001..200000),
      (200001..300000),
      (300001..400000),
      (400001..500000),
      (500000..1000000000000)
    ]
    
    count_by(property, "units.annual_income").each do |hash|
      income = hash["_id"]["dimension"]
      range = income_range.detect{|r| r.include?(income) }
      
      if range
        first = range.first.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        last = range.last.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        
        pp ">>>", range, first, last
        if first == "500,000"
          range = "Over $#{first}"
        else
          range = "$#{first} - $#{last}"
        end
      end
      
      ResidentMetric.create({
        :property_id => property.id,
        :type => "units.annual_income",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => hash["_id"]["dimension"],
        :total => hash["count"]
      })
      
      ResidentMetric.create({
        :property_id => property.id,
        :type => "income_range",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => range,
        :total => hash["count"]
      })
    end

    age_range = [ 
      (0..5),
      (6..12),
      (13..18),
      (19..25),
      (26..30),
      (31..40),
      (41..50),
      (51..60),
      (61..70),
      (71..80),
      (81..800) 
    ]
    
    count_by_year_of_birth(property).each do |hash|
      age = hash["_id"]["dimension"] ? Date.today.year - hash["_id"]["dimension"] : nil 
      range = age ? age_range.detect{|r| r.include?(age) }.to_s.gsub("..", "-").gsub("81-800", "80+") : nil
      
      ResidentMetric.create({
        :property_id => property.id,
        :type => "age_range",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => range,
        :total => hash["count"]
      })
      
      ResidentMetric.create({
        :property_id => property.id,
        :type => "age",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => age,
        :total => hash["count"]
      })
    end
    
    total_cars(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_cars",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :total => hash["count"]
      })
    end
    
    total_pets(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_pets",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => hash["_id"]["dimension"],
        :total => hash["count"]
      })
    end
    
    total_pet_type(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "units.pet_type",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :dimension => hash["_id"]["dimension"],
        :total => hash["count"]
      })
    end
    
    total_residents(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_residents",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :total => hash["count"]
      })
    end
    
    total_residents_with_pets(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_residents_with_pets",
        :status => hash["_id"]["status"],
        :rental_type => hash["_id"]["rental_type"],
        :total => hash["count"]
      })
    end
    
    # comparative reports (does not categorize by status)
    Unit.where(:property_id => property.id).select("count(id) as ids_count, rental_type").group("rental_type").each do |m|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_units",
        :rental_type => m.rental_type,
        :total => m.ids_count
      })
    end
    
    total_occupied_units(property).each do |hash|
      ResidentMetric.create({
        :property_id => property.id,
        :type => "total_occupied_units",
        :rental_type => hash["_id"]["rental_type"],
        :total => hash["count"]
      })
    end
  end

  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(1)
  end
  
  def self.count_by(property, field)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "#{field}" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "#{field}" => {"$nin" => [nil, ""]}
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type",
            :dimension => "$#{field}"
          }, 
          :count => { 
            "$sum" => 1 
          }
        } 
      }
    ])
  end
  
  def self.count_by_year_of_birth(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "birthday" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "birthday" => {"$type" => 9}
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type",
            :dimension => { "$year" => "$birthday" }
          }, 
          :count => { 
            "$sum" => 1 
          }
        } 
      }
    ])
  end
  
  def self.total_cars(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "units.vehicles_count" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "units.vehicles_count" => {"$gt" => 0}
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type"
          }, 
          :count => { 
            "$sum" => "$units.vehicles_count"
          }
        } 
      }
    ])
  end
  
  def self.total_pets(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "units.pets_count" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "units.pets_count" => { "$gt" => 0 }
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type"
          }, 
          :count => { 
            "$sum" => "$units.pets_count"
          }
        } 
      }
    ])
  end
  
  def self.total_residents(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type"
          }, 
          :count => { 
            "$sum" => 1
          }
        } 
      }
    ])
  end
  
  def self.total_residents_with_pets(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "units.pets_count" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "units.pets_count" => { "$gt" => 0 }
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type"
          }, 
          :count => { 
            "$sum" => 1 
          }
        } 
      }
    ])
  end
  
  def self.total_pet_type(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1,
          "units.pet_type" => 1,
          "units.pets_count" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "units.pets_count" => { "$gt" => 0 },
          "units.pet_type" => {"$nin" => [nil, ""]}
        }
      },
      { 
        "$group" => { 
          :_id => {
            :status => "$units.status",
            :rental_type => "$units.rental_type",
            :dimension => "$units.pet_type"
          }, 
          :count => { 
            "$sum" => 1 
          }
        } 
      }
    ])
  end
  
  def self.total_occupied_units(property)
    Resident.collection.aggregate([
      {
        "$match"=> {
          "units.property_id"=> property.id.to_s
        }
      },
      {
        "$project"=> {
          "units.property_id" => 1,
          "units.status" => 1,
          "units.rental_type" => 1
        }
      },
      {
        "$unwind"=>"$units"
      },
      {
        "$match"=> {
          "units.property_id" => property.id.to_s,
          "units.status" => "Current"
        }
      },
      { 
        "$group" => { 
          :_id => {
            :rental_type => "$units.rental_type"
          }, 
          :count => { 
            "$sum" => 1 
          }
        } 
      }
    ])
  end

end