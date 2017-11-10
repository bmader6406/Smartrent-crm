# Usage: bin/rake utils:analyse_residents

require "pp"

def equals(record1, record2)
    candidates = ["resident_id", "property_id", "unit_code", "move_in_date"];
    candidates.each do |k|
        return false unless record1[k] == record2[k]
    end
    true
end

def conflicts(record1, record2)
    candidates1 = ["resident_id", "property_id", "unit_code", "move_in_date"];
    candidates2 = ["status"];
    candidates1.each do |k|
        return false unless record1[k] == record2[k]
    end
    candidates2.each do |k|
        return false if record1[k] == record2[k]
    end
    true
end

def compare_resident_units(ru1,ru2)
    if(ru1.move_out.nil? and ru2.move_out.nil?)
        if(ru1.updated_at == ru2.updated_at)
            (ru1.created_at>ru2.created_at) ? ru1 : ru2
        else
            (ru1.updated_at>ru2.updated_at) ? ru1 : ru2
        end
    elsif(!ru1.move_out.nil? and !ru2.move_out.nil?)
        (ru1.move_out<ru2.move_out) ? ru1 : ru2
    else
        (ru1.move_out.nil? ? ru1 : ru2 )
    end
end
def last_awarded_month(property)
  last = false
  last_rewarded = Smartrent::Reward.where(:property_id => property.id,:type_ => 2)
  if (last_rewarded.count != 0 )
    last = last_rewarded.last.period_start.advance(:hours => 5)
    #pp "=============================>\nName:#{property.name} last_awarded:#{last}\n=============================>\n"
  end
  last
end

def get_time_diff_str(time_start,time_end)
    t_diff = time_end-time_start
    ms = (((time_end-time_start)-(time_end-time_start).to_i)*1000).to_i
    seconds_diff = (time_end-time_start).to_i.abs
    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600
    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60
    seconds = seconds_diff
    t = "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}:#{ms.to_s.rjust(3, '0')}"
    t
end

def filter_email(email,table = Resident)
  # filer's email or return false if invalid email(email and unit already exist)
  msg = ""
  email_temp = email
  email_temp = email.split(";").first.strip if email.include?(";") && email.scan("@").length > 1 || email[-1] == ";" 
  email_temp = email.split(",").first.strip if email.include?(",") && email.scan("@").length > 1 || email[-1] == ","
  return false if email_temp == ""
  query = table.where(:email => email_temp)
  if query.count > 0 && email_temp != email 
    # if already a resident with the email is present(resident_original) check whether it is same unit
    # if different unit (resident_property) or different status then copy it to the original resident account
    # destroy the test email(resident_current) if the unit already exist or all unit has been copied
    if table == Resident 
      #Mongodb table
      resident_original = query.first
      resident_current = table.where(:email => email).first
      resident_current.units.each do |unit|
        unit_exist = resident_original.units.where(:unit_id => unit.unit_id, :property_id => unit.property_id, :status => unit.status).count
        if unit_exist > 0
          msg << "[Mongo]Resident::destroy the unit #{unit.unit_id} for #{email}"
            resident_current.units.find(unit._id.to_s).destroy
            if resident_current.units.count == 0
              msg << "[Mongo]Resident::destroy the resident #{email}"
              resident_current.destroy
              # msg << "[Mysql]Smartrent::Resident::destroy the resident #{email}"
              # sr = Smartrent::Resident.where(:email => resident_current.email)
              # sr.first.destroy if sr.count > 0
            end
        else
            msg << "[Mongo]Resident::destroy the unit after copying the unit #{unit.unit_id} for #{email}"
            t = unit.dup
            resident_original.units << t
            resident_current.units.find(unit._id.to_s).destroy
            if resident_current.units.count == 0
              msg << "[Mongo]Resident::destroy the resident #{email}"
              resident_current.destroy
              # msg << "[Mysql]Smartrent::Resident::destroy the resident #{email}"
              # sr = Smartrent::Resident.where(:email => resident_current.email)
              # sr.first.destroy if sr.count > 0
            end
        end
      end
    end
  elsif email_temp != email 
    msg = "Create new Resident" if msg == ""
    resident_current = Resident.where(:email => email).first
    resident_current.email = email_temp
    resident_current.email_lc = email_temp.downcase
    resident_current.save
  end
  msg = "No change" if msg == "" && email_temp == email
  # email_temp = email_temp.split(".com").first + ".com" #remove text after .com
  return email_temp, msg
end

namespace :utils do
    desc "This task does something"
    task :analyse do
      puts "Task started"
      Smartrent::Resident.where(:smartrent_status => "Active").limit(10).each do |r|
        puts "Inside loop"
        pp r
      end
      puts "Task finished"
    end

    task :temporary_task => :environment do
      ActiveRecord::Base.logger.level = 1
      sql = "UPDATE smartrent_resident_properties SET move_out_date=NULL where status like 'current';"
      ActiveRecord::Base.connection.execute(sql)
      pp "All move out date of current residents made to null"
      meta = {"file_name" => "/reporting/yardi/bozzuto_yardi_residents/YardiResidents-Full-20171022.csv"}
      meta["recipient"]="admin+local@bozzutosmartrent.com"
      meta["incremental_upload"]=1
      import = Import.find(2)
      tmp_file = "/mnt/crm-smartrent/tmp/resident_importer.csv"
      ResidentImporter.perform(tmp_file, "yardi", import.field_map, meta)
    end
    
    task :combined_task => :environment do
        start = Time.now
        pp "Starting Non-Res Removal Task..."
        Rake::Task["utils:remove_resident_with_name_nonres"].invoke
        pp "Completed Non-Res Task!"
        pp "Starting email filtering Task..."
        Rake::Task["utils:remove_invalid_email"].invoke
        pp "Completed email filtering Task!"
        pp "Starting duplicate units removal Task..."
        Rake::Task["utils:remove_duplicate_resident_properties"].invoke
        pp "Completed duplicate units removal Task!"
        pp "Starting resident rewards reset Task..."
        Rake::Task["utils:resident_rewards_reset"].invoke
        pp "Completed duplicate units removal Task!"
        pp "Time Taken for complete Task: #{get_time_diff_str(start,Time.now)}"
    end

    task :remove_resident_with_name_nonres => :environment do
        ActiveRecord::Base.logger.level = 1
        time_start = Time.now
        timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
        file_name_csv = TMP_DIR + "task_log/remove_resident_with_name_nonres_"+timestamp+".csv"
        total_residents = Resident.all.count
        total_residents_digits_count = total_residents.to_s.length
        r_count = 0
        p "Total Residents:#{total_residents}"
        p "Executing Residents..."
        success_count = 0
        fail_count = 0
        CSV.open(file_name_csv, "w") do |csv|
          csv << ["ID","Email","Message"]
          Resident.all.each do |resident|
            r_count += 1
            percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
            now = Time.now
            print "#{r_count.to_s.rjust(total_residents_digits_count,'0')}/#{total_residents} (#{sprintf("%.2f",percentage).to_s.rjust(5,'0')}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
            begin
              full_name = (resident.first_name.to_s + " " + resident.last_name.to_s).gsub("-", "").upcase
              if full_name ==  "NONRES" or full_name.start_with?("NONRES ") or full_name.end_with?(" NONRES") or full_name.start_with?("NON RES")
                sr = Smartrent::Resident.find_by_crm_resident_id(resident._id)
                sr.destroy if sr
                resident.destroy
              end
              csv << [resident.id,resident.email,"Success"]
              success_count += 1
            rescue  Exception => e
              error_details = "#{e.class}: #{e}"
              error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
              csv << [resident.id,resident.email,"Failed",error_details]
              fail_count += 1
              next
            end
            time_estimate = now+((total_residents-r_count)*((now-time_start)/r_count.to_f).round(2)).round
            print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\r"
          end
          print "\n"
          time_end = Time.now
          pp "Task Completed"
          t = get_time_diff_str(time_start,time_end)
          p "Time Taken to complete: #{t}"
          p "Total Residents:#{r_count}"
          p "Residents succesfully cleared: #{success_count}"
          p "Residents failed to cleared: #{fail_count}"
          p "log saved in #{file_name_csv}"
          csv << ["Total Residents",r_count.to_s,""]
          csv << ["Time Taken",t,""]
        end   
    end

    task :remove_invalid_email => :environment do
        ActiveRecord::Base.logger.level = 1
        time_start = Time.now
        timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
        file_name_csv = TMP_DIR + "task_log/remove_invalid_email_"+timestamp+".csv"
        CSV.open(file_name_csv, "w") do |csv|
            csv << ["ID","Email","Status","Final Email","Message"]
            query = Resident.where(:email => /[,;]/).order("id DESC")
            # query = Resident.where(:_id => 1572427447241844299)
            total_residents = query.count
            r_count = 0
            p "Total Residents with invalid email: #{total_residents}"
            p "Filtering email..."
            success_count = 0
            fail_count = 0
            total_residents_digits_count = total_residents.to_s.length
            query.each do |r|
                r_count += 1
                percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
                now = Time.now
                print "#{r_count.to_s.rjust(total_residents_digits_count,'0')}/#{total_residents} (#{sprintf("%.2f",percentage).to_s.rjust(5,'0')}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
                begin
                    email, msg = filter_email(r.email)
                    csv << [r.id,r.email,"Success",email, msg]
                    success_count += 1
                rescue Exception => e
                    error_details = ""
                    error_details = "#{e.class}: #{e}"
                    error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
                    csv << [r.id,r.email,"Failed",error_details]
                    fail_count += 1
                end
                time_estimate = now+((total_residents-r_count)*((now-time_start)/r_count.to_f).round(2)).round
                print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\r"
            end
            print "\n" 
            time_end = Time.now
            pp "Task Completed"
            t = get_time_diff_str(time_start,time_end)
            p "Time Taken to complete: #{t}"
            p "Total Residents: #{r_count}"
            p "Residents whose email succesfully filtered: #{success_count}"
            p "Residents failed to filter: #{fail_count}"
            p "log saved in #{file_name_csv}"
            csv << ["Total Residents",r_count.to_s,""]
            csv << ["Time Taken",t,""]
        end
    end

    task :remove_duplicate_resident_properties => :environment do
        ActiveRecord::Base.logger.level = 1
        time_start = Time.now
        timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
        file_name_csv = TMP_DIR + "task_log/remove_duplicate_resident_properties_"+timestamp+".csv"
        total_residents = Resident.all.count
        total_residents_digits_count = total_residents.to_s.length
        r_count = 0
        p "Total Residents:#{total_residents}"
        p "Executing Residents..."
        success_count = 0
        fail_count = 0
        CSV.open(file_name_csv, "w") do |csv|
            csv << ["ID","Email","Message"]
            Resident.all.each do |resident|
            # resident =  Resident.where(email: "Samiralr@yahoo.com").first
                r_count += 1
                percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
                now = Time.now
                print "#{r_count}/#{total_residents} (#{sprintf("%.2f",percentage).to_s.rjust(5,'0')}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
                begin
                    to_remove = []
                    resident.units.each do |ru1|
                        ru = resident.units.where( property_id: ru1.property_id).order_by(updated_at: 'desc')
                        ru = ru.select{ |unit| unit.unit_code == ru1.unit_code}
                        tmp = ru.first
                        to_remove += ru.select{|x| x._id.to_s != tmp._id.to_s}
                    end
                    if to_remove.count > 0
                        to_remove.each do |r|
                            r.destroy
                        end 
                    end
                    # sr = Smartrent::Resident.find_by_crm_resident_id(resident._id)
                    # if sr 
                    #     sr.resident_properties.each do |sr1|
                    #         rp = sr.resident_properties.where(property_id: sr1.property_id, unit_code: sr1.unit_code).order(updated_at: 'desc').first
                    #         sr.resident_properties.where(property_id: sr1.property_id, unit_code: sr1.unit_code).where.not(id: rp.id).destroy_all if rp
                    #     end
                    # end
                    csv << [resident.id,resident.email,"Success"]
                    success_count += 1
                rescue  Exception => e
                    error_details = "#{e.class}: #{e}"
                    error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
                    csv << [resident.id,resident.email,error_details]
                    fail_count += 1
                    next
                end
                # pp "percentage: #{percentage}|time_start: #{time_start}|now: #{now}"
                time_estimate = now+((total_residents-r_count)*((now-time_start)/r_count.to_f).round(2)).round
                print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\r"
            end
            print "\n"
            time_end = Time.now
            pp "Task Completed"
            t = get_time_diff_str(time_start,time_end)
            p "Time Taken to complete: #{t}"
            p "Total Residents:#{r_count}"
            p "Residents succesfully reset: #{success_count}"
            p "Residents failed to reset: #{fail_count}"
            p "log saved in #{file_name_csv}"
            csv << ["Total Residents",r_count.to_s,""]
            csv << ["Time Taken",t,""]
        end
    end

    task :resident_rewards_reset => :environment do
        ActiveRecord::Base.logger.level = 1
        time_start = Time.now
        timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
        file_name_csv = TMP_DIR + "task_log/residents_rewards_"+timestamp+".csv"
        CSV.open(file_name_csv, "w") do |csv|
            csv << ["ID","Email","Message"]
            query = Smartrent::Resident.all.order("id DESC")
            # query = query.limit(5) #if limit
            total_residents = query.count
            # query = Smartrent::Resident.where(:id=>10466) #if id
            r_count = 0
            p "Total Residents:#{total_residents}"
            p "Executing Residents..."
            success_count = 0
            fail_count = 0
            total_residents_digits_count = total_residents.to_s.length
            query.find_in_batches do |residents|
                residents.each do |r|
                    r_count += 1
                    percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
                    now = Time.now
                    print "#{r_count.to_s.rjust(total_residents_digits_count,'0')}/#{total_residents} (#{sprintf("%.2f",percentage).to_s.rjust(5,'0')}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
                    begin
                        r.resident_properties.first.reset_rewards_table if (r.resident_properties.count > 0)
                        csv << [r.id,r.email,"Success"]
                        success_count += 1
                    rescue Exception => e
                        error_details = ""
                        error_details = "#{e.class}: #{e}"
                        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
                        csv << [r.id,r.email,error_details]
                        fail_count += 1
                    end
                    time_estimate = now+((total_residents-r_count)*((now-time_start)/r_count.to_f).round(2)).round
                    print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\r"
                end
            end
            print "\n" 
            time_end = Time.now
            pp "Task Completed"
            t = get_time_diff_str(time_start,time_end)
            p "Time Taken to complete: #{t}"
            p "Total Residents:#{r_count}"
            p "Residents succesfully reset: #{success_count}"
            p "Residents failed to reset: #{fail_count}"
            p "log saved in #{file_name_csv}"
            csv << ["Total Residents",r_count.to_s,""]
            csv << ["Time Taken",t,""]
        end
    end

    task :find_smartrent_change_date do
        total = 0;
        timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
        CSV.open(TMP_DIR + "task_log/property"+timestamp+".csv", "w") do |csv|
            column_names = ["id","property_name","last_awarded_date"]
            csv << column_names
            properties = Property.all.each do |pr|
                last = last_awarded_month(pr)
                if last
                    value = [pr.id.to_s,pr.name.to_s,last.to_s]
                    csv << value
                    total = total+1
                end
            end
            Rails.logger.info("Records count: "+total.to_s)
            Rails.logger.info("Task finished")
        end
    end

    task :resident_conflicts do
        total = 0
        count = 0
        timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
        puts "Task started"
        CSV.open("task_log/residents_conflicts_"+timestamp+".csv", "w") do |csv1|
            csv1 << ["id", "email", "first name", "last name", "smartrent status", "balance", 
                        "expiry date", "first move-in", "current property", "current unit",
                        "resident status", "move-in date", "move-out date", "unit code"
                                ]
            Smartrent::Resident.where("balance >= 0").order(:email).each do |r|
                total = total + 1
                r.resident_properties.each do |h|
                    r.resident_properties.each do |h2|
                        unless h==h2
                            if conflicts(h,h2)
                                count = count + 1
                                p 'Found conflicting entry ' + count.to_s
                                csv1 << [r.id.to_s+"-"+h.id.to_s, r.email, r.first_name, r.last_name, r.smartrent_status, r.balance, 
                                r.expiry_date, r.first_move_in, r.current_property_id, r.current_unit_id,
                                h.status, h.move_in_date, h.move_out_date, h.unit_code]
                            end
                        end
                        
                    end
                end
                
            end
            p "Residents count: "+total.to_s
            p "Records exported: "+count.to_s
            puts "Task finished"
        end
    end

    task :analyse_residents do
        total = 0
        count = 0
        timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
        puts "Task started"
        CSV.open("task_log/residents"+timestamp+".csv", "w") do |csv|
            csv << Smartrent::Resident.column_names
            Smartrent::Resident.where(:smartrent_status => "Active",).where("balance < 9900").each do |r|
                total = total + 1
                if r.monthly_awards_amount == 0 and r.total_months > 0
                    count = count + 1
                    puts r.email
                    csv << r.attributes.values
                end
            end
            p "Residents count: "+total.to_s
            p "Residents exported: "+count.to_s
            puts "Task finished"
        end
    end

    task :analyse_all_residents do
        total = 0
        count = 0
        timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
        puts "Task started"
        residents_in_multipleunits = Array.new
        CSV.open("task_log/residents_2_"+timestamp+".csv", "w") do |csv2|
            # csv1 << Smartrent::Resident.column_names.each {|column| column.humanize } 
            csv2 << ["id", "email", "first name", "last name", "smartrent status", "balance", 
                        "expiry date", "first move-in", "current property", "current unit",
                        "resident status", "move-in date", "move-out date", "unit code"
                                ]
            Smartrent::Resident.where("balance >= 0").order(:email).each do |r|
                history = {:applicant => 0, :future => 0, :current => 0, :past => 0}
                r.resident_properties.each do |h|
                    history[h.status.downcase.to_sym] += 1 if history.key?(h.status.downcase.to_sym)                    
                end
                if history[:current] > 1
                    puts r.id.to_s+" :: "+r.email
                    p "    has "+history[:current].to_s+" current type records in resident history"
                    r.resident_properties.each do |h|
                        if h.status == "Current"
                            count = count + 1
                            csv2 << [r.id.to_s+"-"+h.id.to_s, r.email, r.first_name, r.last_name, r.smartrent_status, r.balance, 
                                r.expiry_date, r.first_move_in, r.current_property_id, r.current_unit_id,
                                h.status, h.move_in_date, h.move_out_date, h.unit_code]
                        end
                    end
                end
            end
            p "Residents count: "+total.to_s
            p "Residents exported: "+count.to_s
            puts "Task finished"
        end
    end

    task :resident_dupes do
        total = 0
        count = 0
        timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
        puts "Task started"
        CSV.open("task_log/residents_dupes_"+timestamp+".csv", "w") do |csv1|
            csv1 << ["id", "email", "first name", "last name", "smartrent status", "balance", 
                        "expiry date", "first move-in", "current property", "current unit",
                        "resident status", "move-in date", "move-out date", "unit code"
                                ]
            Smartrent::Resident.where("balance >= 0").order(:email).each do |r|
                total = total + 1
                r.resident_properties.each do |h|
                    r.resident_properties.each do |h2|
                        unless h==h2
                            if equals(h,h2)
                                count = count + 1
                                p 'Found a duplicate entry ' + count.to_s
                                csv1 << [r.id.to_s+"-"+h.id.to_s, r.email, r.first_name, r.last_name, r.smartrent_status, r.balance, 
                                r.expiry_date, r.first_move_in, r.current_property_id, r.current_unit_id,
                                h.status, h.move_in_date, h.move_out_date, h.unit_code]
                            end
                        end
                        
                    end
                end
                
            end
            p "Residents count: "+total.to_s
            p "Records exported: "+count.to_s
            puts "Task finished"
        end
    end
end


namespace :csv do
  desc "find duplicates from CSV file on given column"
  # Usage: rake csv:find_duplicates["2017.04.07-Export.csv",1] 
  timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
  task :find_duplicates, [:file, :column] do |t, args|
    args.with_defaults(column: 0)
    values = []
    index  = args.column.to_i
    # parse given file row by row
    File.open(args.file, "r").each_slice(1) do |line|
      # get value of the given column
      values << line.first.split(',')[index]
    end
    # compare length with & without uniq method 
    puts values.uniq.length == values.length ? "File does not contain duplicates" : "File contains duplicates"
  end
end