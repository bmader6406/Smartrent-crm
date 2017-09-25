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
	t = "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}:#{ms.to_s.rjust(2, '0')}"
	t
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

  	task :analyse_residents do
		total = 0
		count = 0
		timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
		puts "Task started"
		CSV.open("tmp/residents"+timestamp+".csv", "w") do |csv|
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
		CSV.open("tmp/residents_2_"+timestamp+".csv", "w") do |csv2|
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
		CSV.open("tmp/residents_dupes_"+timestamp+".csv", "w") do |csv1|
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

	task :remove_duplicate_resident_properties => :environment do
    	ActiveRecord::Base.logger.level = 1
    	time_start = Time.now
		timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
		file_name_csv = "tmp/residents_properties_"+timestamp+".csv"
		residents = Resident.all.limit(10000)
    	total_residents = Array(residents).length
    	r_count = 0
  		p "Total Residents:#{total_residents}"
  		p "Executing Residents..."
  		success_count = 0
  		fail_count = 0
		CSV.open(file_name_csv, "w") do |csv|
			csv << ["ID","Email","Message"]
			residents.each do |resident|
				r_count += 1
	  			percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
	  			now = Time.now
	  			print "#{r_count}/#{total_residents} (#{percentage}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
				begin
					
					
					resident.units.each do |ru1|
						ru = resident.units(unit_code: ru1.unit_code, property_id: ru1.property_id).order_by(updated_at: 'desc').first
						resident.units(unit_code: ru1.unit_code, property_id: ru1.property_id).not_in(_id: ru.id.to_s).destroy_all if ru
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
				temp = ((100-percentage)*((now-time_start)/percentage))
				time_estimate = now+temp
	  			print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\n"
        	end
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


	task :resident_conflicts do
		total = 0
		count = 0
		timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
		puts "Task started"
		CSV.open("tmp/residents_conflicts_"+timestamp+".csv", "w") do |csv1|
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

	task :resident_rewards_reset => :environment do
    ActiveRecord::Base.logger.level = 1
		time_start = Time.now
		timestamp = time_start.strftime('%Y-%m-%d_%H-%M-%S')
		file_name_csv = "tmp/residents_rewards_"+timestamp+".csv"
		CSV.open(file_name_csv, "w") do |csv|
			csv << ["ID","Email","Message"]
			query = Smartrent::Resident.all.order("id DESC").limit(1000)
	  		# query = query.limit(5) #if limit
	  		total_residents = query.count
	  		# query = Smartrent::Resident.where(:id=>10466) #if id
	  		r_count = 0
	  		p "Total Residents:#{total_residents}"
	  		p "Executing Residents..."
	  		success_count = 0
	  		fail_count = 0
	  		query.each do |r|
	  			r_count += 1
	  			percentage = (((r_count.to_f/total_residents)*10000).round)/100.to_f
	  			now = Time.now
	  			print "#{r_count}/#{total_residents} (#{percentage}%) | Time elapsed: #{get_time_diff_str(time_start,now)} "
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
	  				next
	  			end
	  			time_estimate = now+((100-percentage)*((now-time_start)/percentage))
	  			print "| Estimated Time Remaining: #{get_time_diff_str(now,time_estimate)}\n"
	  		end
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
        CSV.open("tmp/property"+timestamp+".csv", "w") do |csv|
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