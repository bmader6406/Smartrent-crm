class Import < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  
  has_many :logs, :class_name => "ImportLog"
  
  default_scope { where(:deleted_at => nil) }
  
  def ftp_setting
    @ftp_setting ||= begin
      hash = JSON.parse(self[:ftp_setting]) rescue {}
      
      if hash.empty?
        if type.include?("load_units")
          hash = default_units_ftp_setting
          
        elsif type.include?("load_yardi")
          hash = default_yardi_ftp_setting
          
        elsif type.include?("load_non_yardi")
          hash = default_non_yardi_ftp_setting
          
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
        if type.include?("load_yardi")
          hash = default_yardi_field_map
        
        elsif type.include?("load_non_yardi_master")
          hash = default_non_yardi_master_field_map
          
        elsif type.include?("load_non_yardi")
          hash = default_non_yardi_field_map
          
        end
      end
      
      hash
    end
  end
  
  def field_map=(data)
    #pp ">>>>", data
    self[:field_map] = (@field_map || field_map).merge(data).to_json
  end
  
  def property_map
    @property_map ||= JSON.parse(self[:property_map]) rescue {}
  end
  
  def property_map=(data)
    #pp ">>>>", data
    self[:property_map] = (@property_map || property_map).merge(data).to_json
  end
  
  ###
  
  def default_units_ftp_setting
    {
      "host" => "feeds.livebozzuto.com",
      "username" => "CRMbozchh",
      "password" => "NAQpPt41",
      "file_name" => "mits4_1.xml",
      "recipient" => ADMIN_EMAIL
    }
  end
  
  def default_yardi_ftp_setting
    {
      "host" => "bozzutofeed.qburst.com",
      "username" => "bozzutofc",
      "password" => "6zxXRETm",
      "file_name" => "/reporting/yardi/bozzuto_yardi_residents/YardiResidents-Full-%Y%m%d.csv",
      "recipient" => ADMIN_EMAIL
    }
  end
  
  def default_non_yardi_ftp_setting
    {
      "host" => "bozzutofeed.qburst.com",
      "username" => "bozzutofc",
      "password" => "6zxXRETm",
      "path" => "/reporting/nonbozzutopmsdrop/yardi_ta",
      "recipient" => ADMIN_EMAIL
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
      "household_status" => "21",
      "previous_residence" => "22",
      "moving_from" => "23",
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
  
  def default_non_yardi_field_map
    {
      "non_yardi_property_id" => "0",
      "first_name" => "2",
      "last_name" => "3",
      "email" => "4",
      "move_in" => "5",
      "move_out" => "6",
      "status" => "7",
      "tenant_code" => "8",
      "unit_code" => "9"
    }
  end
  
  def default_non_yardi_master_field_map
    {
      "elan_number" => "0",
      "first_name" => "3",
      "last_name" => "4",
      "email" => "5",
      "move_in" => "6",
      "move_out" => "7",
      "status" => "8",
      "tenant_code" => "9",
      "unit_code" => "10"
    }
  end
  
end
