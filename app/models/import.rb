class Import < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  
  def ftp_setting
    @ftp_setting ||= begin
      hash = JSON.parse(self[:ftp_setting]) rescue {}
      
      if hash.empty?
        if type.include?("units")
          hash = default_units_ftp_setting
          
        elsif type.include?("yardi")
          hash = default_yardi_ftp_setting
        end
      end
      
      hash
    end
  end
  
  def ftp_setting=(data)
    #pp ">>>>", data
    self[:ftp_setting] = (@ftp_setting || ftp_setting).merge(data).to_json
  end
  
  def field_map
    @field_map ||= begin
      hash = JSON.parse(self[:field_map]) rescue {}
      
      if hash.empty?
        if type.include?("yardi")
          hash = default_yardi_field_map
        end
      end
      
      hash
    end
  end
  
  def field_map=(data)
    #pp ">>>>", data
    self[:field_map] = (@field_map || field_map).merge(data).to_json
  end
  
  ###
  
  def default_units_ftp_setting
    {
      "host" => "feeds.livebozzuto.com",
      "username" => "CRMbozchh",
      "password" => "NAQpPt41",
      "file_name" => "mits4_1.xml",
      "recipient" => "tn@hy.ly"
    }
  end
  
  def default_yardi_ftp_setting
    {
      "host" => "ftp.hy.ly",
      "username" => "yardi",
      "password" => "yardi1206",
      "file_name" => "/daily/YardiResidents-Full-%Y%m%d.csv",
      "recipient" => "tn@hy.ly"
    }
  end
  
  def default_yardi_field_map
    {
      "yardi_property_id" => "0",
      "unit_code" => "1",
      "tenant_code" => "2",
      "full_name" => "3",
      "street" => "4",
      "city" => "6",
      "state" => "7",
      "zip" => "8",
      "status" => "9",
      "email" => "10",
      "move_in" => "11",
      "move_out" => "12",
      "household_size" => "13",
      "pets_count" => "14",
      "lead_source" => "16",
      "gender" => "17",
      "birthday" => "18",
      "last4_ssn" => "19",
      "household_size" => "20",
      "household_status" => "21",
      "previous_residence" => "22",
      "moving_from" => "23",
      "pets_count" => "24",
      "pet_1_type" => "25",
      "pet_1_breed" => "26",
      "occupation_type" => "27",
      "employer" => "28",
      "employer_city" => "29",
      "employer_state" => "30",
      "annual_income" => "31",
      "minutes_to_work" => "32",
      "transportation_to_work" => "33",
      "license1" => "34",
      "vehicles_count" => "35"
    }
  end
end