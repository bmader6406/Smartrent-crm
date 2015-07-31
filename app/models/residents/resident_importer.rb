# Import Yardi CSV file

require 'csv'

class ResidentImporter
  def self.queue
    :crm_immediate
  end
  
  #TODO: create and set unit_id
  def self.perform(file_path)
    resident_map = {
     :yardi_property_id => 0,
     :unit_code => 1,
     :origin_id => 2,
     :full_name => 3,
     :street => 4,
     :city => 6,
     :state => 7,
     :zip => 8,
     :status => 9,
     :email => 10,
     :move_in => 11,
     :move_out => 12,
     :household_size => 13,
     :pets_count => 14
    }

    prop_map = {}

    Property.all.each do |p|
      prop_map[p.yardi_property_id.to_s.gsub(/^0*/, '')] = p.id
    end

    index = 0
    
    File.foreach(file_path) do |line|
      index += 1
      
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if index == 1 || row.join.blank?

          property_id = prop_map[row[ resident_map[:yardi_property_id] ].to_s.gsub(/^0*/, '') ]
      
          next if !property_id
      
          unit_code = row[ resident_map[:unit_code] ]
          email = row[ resident_map[:email] ]
      
          next if !email
      
          unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
          unit.save(:validate => false)
      
          pp "#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"
      
          #consolidate resident by email
          resident = Resident.with(:consistency => :strong).where(:email_lc => email.to_s.downcase ).unify_ordered.first
          resident = Resident.new if !resident

          Resident::CORE_FIELDS.each do |f|
            if resident_map[f]
              if [:full_name].include?(f)
                resident.full_name = row[resident_map[f]]
              else
                resident[f] = row[resident_map[f]]
              end

              if [:birthday].include?(f)
                resident[f] = Date.strptime(row[resident_map[f]], '%m/%d/%Y') rescue nil
              end
            end
          end

          property_attrs = {
            :property_id => property_id
          }

          Resident::PROPERTY_FIELDS.each do |f|
            property_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?
        
            #pp "property field: #{f}, #{property_attrs[f]}"

            if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
              property_attrs[f] = Date.strptime(property_attrs[f], '%Y%m%d') rescue nil
            end
        
            if [:unit_id].include?(f) && property_attrs[f] && unit
              property_attrs[f] = unit.id
            end
          end
          
          if resident.save
            #create submit
            resident.sources.create(property_attrs) if property_attrs[:property_id]
          end

        end
      
      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        pp ">>> line: #{line}, ERROR:", error_details
      end
    end
    
  end
end