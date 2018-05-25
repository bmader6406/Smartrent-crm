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

        elsif type.include?("load_xml_property_importer")
          hash = default_xml_ftp_setting
          
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

        elsif type.include?("load_xml_property_importer")
          hash = default_property_xml_field_map

        end
      end

      hash
    end
  end

  def field_map=(data)
    #pp ">>>>", data
    self[:field_map] = (@field_map || field_map).merge(data).to_json rescue {}
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

  def default_xml_ftp_setting
    {
      "host" => "feeds.livebozzuto.com",
      "username" => "Smarbozkrn",
      "password" => "jtLQig4W",
      "file_name" => "mits4_1.xml",
      "recipient" => ADMIN_EMAIL
    }
  end


  def default_yardi_ftp_setting
    {
      "host" => "bozzutofeed.qburst.com",
      "username" => "ftpcrm",
      "password" => "i9aMkVUGigzpo",
      "file_name" => "/bozzuto_yardi_residents/YardiResidents-Full-%Y%m%d.csv",
      "recipient" => ADMIN_EMAIL
    }
  end
  
  def default_non_yardi_ftp_setting
    {
      "host" => "bozzutofeed.qburst.com",
      "username" => "ftpcrm",
      "password" => "i9aMkVUGigzpo",
      "path" => "/non_bozzuto_yardi_residents/noyardiresidents%Y%m%d.csv",
      "recipient" => ADMIN_EMAIL
    }
  end


  def default_yardi_field_map
    {
      "elan_number" => "0",
      "yardi_property_id" => "1",
      "property_name" => "2",
      "first_name" =>"3",
      "last_name" => "4",
      "email" => "5",
      "move_in" => "6",
      "move_out" => "7",
      "status" => "8",
      "unit_code" => "9",
      "tenant_code" => "10",
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
  
  def default_property_xml_field_map
    {
      :origin_id => ["IDValue"],
      :name => ["PropertyID","MarketingName"],
      :address_line1 => ["PropertyID","Address","AddressLine1"],
      :city => ["PropertyID","Address","City"],
      :state => ["PropertyID","Address","State"],
      :zip => ["PropertyID","Address","PostalCode"],
      :county => ["PropertyID","Address","CountyName"],
      :email => ["PropertyID","Email"],
      :phone => ["PropertyID","Phone","PhoneNumber"],
      :website_url => ["PropertyID","WebSite"],
      :info => ["Information","OfficeHour"],
      :description => ["Information","LongDescription"],
      :latitude => ["ILS_Identification","Latitude"],
      :longitude =>  ["ILS_Identification","Longitude"],
      :floor_plans => ["Floorplan"],
      :features => ["Amenity"],
      :sync_property_id => ["PropertyID","SyncPropertyID"]
    }
  end

end
