require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")

# - Import Residents from the ftp link and add the new properties


class UnitRefreshWorker
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
      :origin_id => ["Units", "UnitID"],
      :bed => ["Units","UnitBedrooms"],
      :bath => ["Units","UnitBathrooms"],
      :sq_ft => ["Units","MaxSquareFeet"],
      :rental_type => ["Units", "UnitEconomicStatus"],
      :code => ["Units", "MarketingName"]
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
    f = File.read("#{TMP_DIR}mits4_1.xml")
    
    properties = Hash.from_xml(f)
    properties["PhysicalProperty"]["Property"].each do |p|
      name = p.nest(property_map[:name])
      property_origin_id = p.nest(property_map[:origin_id])
      property = Smartrent::Property.where("lower(name) = ? or origin_id=?", name.downcase, property_origin_id).first
      p["ILS_Unit"].each do |u|
        origin_id = u.nest(unit_map[:origin_id])
        pp origin_id
        next if !origin_id.present?
        unit = Unit.where(:origin_id => origin_id).first
        next if !unit
        if property
          unit.property_id = property.id
        end
        ActiveRecord::Base.transaction do
          unit_map.each do |key, value|
            unit[key] = u.nest(value)
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
end
