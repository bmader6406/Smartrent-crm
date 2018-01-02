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

def convert_fake_email?(email_lc)
  return true if [" @", "noemail", "nomail", "notgiven", "didnotgive", "donothave", 
    "donotreply", "notgiven", "nonegiven", "noexist", "noreply",
    "@email.com", "@none.net", "@na.com", "@non.com", "efused@yahoo.com", "@test.com"
  ].any?{|e| email_lc.include?(e) }
  
  return true if ["na@", "no@", "non@", "none@", "unknown@", "no@", "test@"].any?{|e| email_lc.match(/^#{e}/) }
  return true if ["refuse", "refused", "decline", "declined"].any?{|e| email_lc.match(/^#{e}\d*@/) }
  return false
end

namespace :utils do
    desc "This task does something"

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
        # pp "Starting resident rewards reset Task..."
        # Rake::Task["utils:resident_rewards_reset"].invoke
        # pp "Completed duplicate units removal Task!"
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
                    sr = Smartrent::Resident.find_by_crm_resident_id(resident._id)
                    if sr 
                        sr.resident_properties.each do |sr1|
                            rp = sr.resident_properties.where(property_id: sr1.property_id, unit_code: sr1.unit_code).order(updated_at: 'desc').first
                            sr.resident_properties.where(property_id: sr1.property_id, unit_code: sr1.unit_code).where.not(id: rp.id).destroy_all if rp
                        end
                    end
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
            # query = Smartrent::Resident.where(smartrent_status: "Expired")
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

    task :import_missed_records_from_yardi_feed => :environment do
      ActiveRecord::Base.logger.level = 1
      file_name1 = "/mnt/exim-data/temp.csv"
      file_name2 = "/home/mufeed/backup/smartrent/yardi_temp/YardiResidents-Full-20171024.csv"
      number = 0
      print "Started...\n"
      File.foreach(file_name2) do |line|

        number += 1
        print "#{number}\r"
        begin
          CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""').gsub(/\r/, '')) do |row|
            if row[9].downcase == "current" && !row[2].to_s.match(/^r/)
              File.open("/mnt/exim-data/task_log/resident_importer.csv", "a+") do |l|
              l << line
              end
            end
          end
        rescue Exception => e
          File.open("/mnt/exim-data/task_log/resident_importer_skipped.csv", "a+") do |l|
            l << number
            l << ","
          end
        end
      end
      print "\nCompleted....\n"
    end

    task :find_changed_email_id_from_yardi_feed => :environment do
      ActiveRecord::Base.logger.level = 1

      # row[10] : email
      # row[9]  : status
      # row[2]  : tenant_code
      # row[3]  : name
      # row[1]  : unit_code

      file_name1 = "/mnt/exim-data/temp.csv"
      file_name2 = "/home/mufeed/backup/smartrent/yardi_temp/YardiResidents-Full-20171024.csv"
      file_used = file_name2
      number = 0
      print "Started...\n"
      file_output = "/mnt/exim-data/task_log/to_delete_residents_in_mongo.csv"
      file_output2 = "/mnt/exim-data/task_log/residents_does_not_exist_in_mongo.csv"
      CSV.open(file_output, "w+") do |l|
        l << ["Email", "tenant_code"]
      end
      CSV.open(file_output2, "w+") do |l|
        l << ["Email", "tenant_code", "Name"]
      end
      #yardi_id = ["25","26", "71","71a", "95","96", "457", "458"]
      total_lines = `wc -l "#{file_used}"`.strip.split(' ')[0].to_i
      time_start = Time.now
      File.foreach(file_name2) do |line|

        number += 1
        print "#{number}/#{total_lines} (#{(((number.to_f/total_lines)*10000).round)/100.to_f}%) | Time elapsed: #{get_time_diff_str(time_start,Time.now)}\r"
        begin
          CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""').gsub(/\r/, '')) do |row|
            email = row[10]
            tenant_code = row[2].to_s.strip
            unit_code = row[1].to_s.strip
            full_name = row[3].to_s.strip
            # email_filtering
            if email.include?(";") && email.scan("@").length > 1 || email[-1] == ";"
              email = email.split(";").first.strip
            elsif email.include?(",") && email.scan("@").length > 1 || email[-1] == ","
              email = email.split(",").first.strip
            elsif convert_fake_email?(email.to_s.downcase)
              email = tenant_code + "@noemail.yardi"
            end
            #finding residents with tenant_code
            rs = Resident.where({ units: { '$elemMatch' => {tenant_code: tenant_code} } })
            rs.each do |r|
              if r.email_lc != email.downcase
                CSV.open(file_output, "a+") do |l|
                  l << [r.email, tenant_code, unit_code]
                end
              end
            end
            if rs.count == 0
              CSV.open(file_output2, "a+") do |l|
                l << [email, tenant_code, unit_code, full_name]
              end        
            end
          end
        rescue Exception => e
          CSV.open("/mnt/exim-data/task_log/resident_importer_skipped.csv", "w+") do |l|
            l << number
            l << ","
          end
        end
      end
      print "\nCompleted....\n"
      ActiveRecord::Base.logger.level = 0
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

  	task :resolve_mongo_mysql_mismatch => :environment do
 		ActiveRecord::Base.logger.level = 1
 		count = 0
 		mismatch = 0
 		dup_mismatch = 0
 		arr = []
 		total = Resident.all
 		time_start = Time.now
 		timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
 		file_name_csv = TMP_DIR + "task_log/residents_mismatch_"+timestamp+".csv"
 		CSV.open(file_name_csv, "w") do |csv|
 			csv << ["ID","Email","Message"]
 			Resident.all.each do |r|
 				count +=1
 				sr = Smartrent::Resident.find_by_email(r.email_lc)
 				next if !sr
 				r.units.each do |u|
 					test = sr.resident_properties.where(:unit_code => u.unit_code, :property_id => u.property_id)
 					if test.count > 1 
 						csv << [r.id,r.email,"Duplicate"]
 						dup_mismatch += 1
 						test.destroy_all
 						u.save
 					elsif test.first and test.first.status != u.status
 						csv << [r.id,r.email,"Mismatch"]
 						mismatch += 1
 						u.save
 					end
 				end
 				print "#{count}/#{total}\r"
 			end
 		end
 		print "\nCompleted...with #{mismatch} mismatches and #{dup_mismatch} dup_mismatches from total:#{count}\n"
 	end 

 	task :expire_resident_before_smartrent_programe => :environment do
 		ActiveRecord::Base.logger.level = 1
 		time_start = Time.now
 		timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
 		file_name_csv = TMP_DIR + "task_log/residents_expire_"+timestamp+".csv"
 		CSV.open(file_name_csv, "w") do |csv|
 			srs = Smartrent::Resident.where('balance = ? and smartrent_status = ?', 100, 'Inactive')
 			d = DateTime.now.change(:day =>3,:month => 03,:year => 2016)
 			srs.each do |resident|
 				rps = resident.resident_properties
 				pp rps.count if rps.count>0
 				date = rps.max_by{|rp| rp.move_out_date }.move_out_date rescue Time.now
 				if date and date<d
 					pp resident.email
 					csv << [resident.id,resident.email,"Mismatch"]
 					resident.balance = 0
 					resident.smartrent_status = 'Expired'
 					resident.save
 				end
 			end
 		end
 	end

 	task :remove_smartrent_credits_of_roommates => :environment do
 		ActiveRecord::Base.logger.level = 1
 		time_start = Time.now
 		timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
 		file_name_csv = TMP_DIR + "task_log/roommates_expire_"+timestamp+".csv"
 		count = 0
		residents = Resident.all
 		CSV.open(file_name_csv, "w") do |csv|
	 		ActiveRecord::Base.logger.level = 1
			residents.each do |r|
			  	all_roommate = r.units.collect(&:roommate).all?
			  	if all_roommate
			    	sr = Smartrent::Resident.find_by_crm_resident_id r._id
			    	if sr
			    		csv << [sr.id,sr.email,"Mismatch"]
				      	count += 1
				      	sr.delete 
		    		end
		 		end
			end	
 		end
 	end

end