
# Usage: bin/rake export:residents
require "pp"

namespace :export do
    desc "This task does something"
    task :analyse do
       Rails.logger.info("Task started")
      Smartrent::Resident.where(:smartrent_status => "Active").limit(10).each do |r|
        puts "Inside loop"
        pp r
      end
       Rails.logger.info("Task finished")
    end

    task :residents => :environment do
        total = 0
        count = 0
        timestamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
        pp "Task started"
        CSV.open("/home/ubuntu/residents_export_"+timestamp+".csv", "w") do |csv1|
            csv1 << ["id", "email", "first name", "last name", "smartrent status", "balance", 
                        "expiry date", "first move-in", "current property", "current unit",
                        "resident status", "move-in date", "move-out date", "unit code",
                        "gender", "birthday", "primary_phone", "cell_phone", "home_phone", "work_phone",
                        "street", "city", "state", "zip", "country"
                    ]
            Smartrent::Resident.where("balance >= 0").order(:email).each do |r|
                total = total + 1
                # pp r
                r.resident_properties.each do |h|
                    # pp h
                    if h.property.state == "MD"
                        count = count + 1
                        p 'Found a resident in MD ' + count.to_s
                        r2 = nil
                        Resident.where(:email_lc => r.email).each do |res|
                            pp "FOUND: #{res.email}"
                            # pp re
                            r2 = res
                        end
                        begin
                            csv1 << [r.id.to_s+"-"+h.id.to_s, r.email, r.first_name, r.last_name, r.smartrent_status, r.balance, 
                            r.expiry_date, r.first_move_in, r.current_property_id, r.current_unit_id,
                            h.status, h.move_in_date, h.move_out_date, h.unit_code,
                            r2.gender, r2.birthday, r2.primary_phone, r2.cell_phone, r2.home_phone, r2.work_phone,
                            r2.street, r2.city, r2.state, r2.zip, r2.country ]
                        rescue Exception => e
                            error_details = ""
                        end
                        break;
                    end
                end
                pp "Iterating count: "+total.to_s
                pp "Records exported: "+count.to_s
            end

            pp "Records count: "+total.to_s
            pp "Records exported: "+count.to_s
            pp "Task finished"
        end
    end
end