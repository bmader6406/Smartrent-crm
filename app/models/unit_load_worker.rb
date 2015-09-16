require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")

# - Import Residents from the ftp link and add the new properties


class UnitLoadWorker
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time = nil)
    # download xml from ftp
    
    #Floorplan contains all the floor_plans
    unit_map = {
      :origin_id => ["ILS_Unit",0 ,"Units", "UnitID"],
      :bed => ["ILS_Unit",0 ,"Units","UnitBedrooms"],
      :bath => ["ILS_Unit",0 ,"Units","UnitBathrooms"],
      :sq_ft => ["ILS_Unit",0 ,"Units","MaxSquareFeet"],
      :rental_type => ["ILS_Unit", 0, "Units", "UnitEconomicStatus"]
    }
    property_map = {
      :name => ["PropertyID","MarketingName"],
      :origin_id => ["IDValue"]
    }
    #FeaturedButton contains all the features
    
    Net::FTP.open('feeds.livebozzuto.com', 'CRMbozchh', 'NAQpPt41') do |ftp|
      ftp.passive = true
      ftp.getbinaryfile("mits4_1.xml","#{TMP_DIR}mits4_1.xml")
      puts "Ftp downloaded"
    end
    #f = File.read("#{TMP_DIR}bozzuto.xml")
    
    properties = Hash.from_xml(f)
    properties["PhysicalProperty"]["Property"].each do |p|
      origin_id = p.nest(unit_map[:origin_id])
      name = p.nest(property_map[:name])
      next if !origin_id.present?
      next if Unit.where(:origin_id => origin_id).count > 0
      property = Smartrent::Property.where("lower(name) = ? or origin_id=?", name.downcase, property_map[:origin_id]).first
      unit = Unit.new
      if property
        unit.property_id = property.id
      else
        unit.property_id = property_map[:id]
      end
      ActiveRecord::Base.transaction do
        unit_map.each do |key, value|
          unit[key] = p.nest(value)
        end
        unit.updated_by = "xml_feed"
        unit.status = "Active"
        if unit.save!
          puts "A Unit has been saved"
        end
      end
    end
  end
end
