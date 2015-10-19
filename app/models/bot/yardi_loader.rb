require 'csv'
require 'net/ftp'

class YardiLoader
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  # WIP (not needed)
  def self.perform(time = nil, ftp_setting = Resident.ftp_setting, recipient = 'tn@hy.ly, admin@hy.ly');
    time = Time.parse(time) if time.kind_of?(String)
    # download xml from ftp
    
    begin
      file_name = ftp_setting["file_name"]
      tmp_file = "#{TMP_DIR}#{Time.now.to_i}_#{file_name}"
      
      Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile(file_name, tmp_file)
        puts "Ftp downloaded"
      end
      
      index, new_resident, existing_resident, errs = 0, 0, 0, []
      
      resident_map = Resident.ftp_setting["resident_map"].with_indifferent_access

      prop_map = {}

      Property.where(:is_crm => 1).each do |p|
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

            origin_id = row[ resident_map[:origin_id] ]
            unit_code = row[ resident_map[:unit_code] ]
            email = row[ resident_map[:email] ]

            next if email.blank?

            # Don't create unit. Unit must be imported from mits4_1.xml before importing resident
            #unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
            #unit.save(:validate => false)

            unit = Unit.find_by(property_id: property_id, code: unit_code)

            pp "#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

            #consolidate resident by email
            resident = Resident.with(:consistency => :strong).where(:email_lc => email.to_s.downcase ).unify_ordered.first
            resident = Resident.new if !resident
            new_record = resident.new_record?

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
              :property_id => property_id,
              :roommate => origin_id.to_s.match(/^r/) ? true : false
            }

            Resident::PROPERTY_FIELDS.each do |f|
              property_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?

              #pp "property field: #{f}, #{property_attrs[f]}"

              if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
                property_attrs[f] = Date.strptime(property_attrs[f], '%Y%m%d') rescue nil
              end

              if [:unit_id].include?(f) && unit
                property_attrs[f] = unit.id
              end
            end

            if resident.save
              #create submit
              resident.sources.create(property_attrs) if property_attrs[:property_id]

              if new_record
                new_resident += 1
              else
                existing_resident += 1
              end

            else
              errs << resident.errors.full_messages.join(", ")
            end

          end

        rescue Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          pp ">>> line: #{line}, ERROR:", error_details
        end
      end
      
      errFile = nil
      errCSV = nil

      if errs.length > 0
        errFile ="errors_#{file_name}"
      
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
      end
      
      Notifier.system_message("[CRM] Yardi Importing Success",
        email_body(new_resident, existing_resident, errs.length, file_name),
        recipient, {"from" => Notifier::EXIM_ADDRESS, "filename" => errFile, "csv_string" => errCSV}).deliver
    
      pp ">>>", email_body(new_resident, existing_resident, errs.length, file_name)
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[CRM] Yardi Importing FAILURE",
        email_body(new_resident, existing_resident, errs.length, file_name) + "   <br><br> ERROR DETAILS: #{error_details}",
        recipient, {"from" => Notifier::EXIM_ADDRESS}).deliver
        
    end
  end

  def self.email_body(new_resident, existing_resident, error_resident, file_name)
    new_and_existing_resident = new_resident + existing_resident

    return <<-MESSAGE
Your file has been loaded:
<br>
- #{new_and_existing_resident} #{resident_text(new_and_existing_resident)} were imported successfully.
<br>
- #{new_resident} of #{new_and_existing_resident} imported #{resident_text(new_and_existing_resident)} were added to the residents list.
<br>
- #{existing_resident} of #{new_and_existing_resident} imported #{resident_text(new_and_existing_resident)} replaced existing residents.
<br>
- #{error_resident} #{resident_text(error_resident)} were not imported.

<br> 
- Source: #{file_name}.
<br>
<br>
<br>
CRM Help Team
<br>
help@hy.ly

    MESSAGE
  end

  def self.resident_text(count)
    count != 1 ? "residents" : "residents"
  end
  
end
