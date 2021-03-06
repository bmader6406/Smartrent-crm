class ExportResidentMailer
	extend Resque::Plugins::Retry
	@retry_limit = RETRY_LIMIT
	@retry_delay = RETRY_DELAY

	def self.queue
		:crm_immediate
	end

	def self.perform(export_resident_params)
		begin
			residents = set_residents(export_resident_params)
			resident_count = 0
			time_start = Time.now
			timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
			file_name = TMP_DIR + "residents-#{export_resident_params['property_name']}-"+timestamp+".csv"
			column_names = ["Current Property Name", "Current Property State", "SmartRent Property?", "Current Property ZipCode","Resident Email", "Roommate Status", "First Name", "Last Name", "SmartRent Status", "Resident Status", "Gender", "Address", "Smartrent Balance"]
			result = CSV.generate(headers: true) do |csv|
				csv << column_names
				if residents.count > 0
					residents.each do |sr|
						unless sr.get_csv.nil?
							csv << sr.get_csv 
							resident_count = resident_count + 1 
						end
					end
				end
			end
			email = ADMIN_EMAIL if export_resident_params['email'].blank?
			message = email_body(export_resident_params, resident_count)
			meta = {"from" => OPS_EMAIL, "filename" => file_name, "csv_string" => result, "to" => export_resident_params['email']}
			Notifier.system_message("[CRM] Smartrent Residents Export SUCCESS", message, export_resident_params['email'], meta).deliver_now
		rescue Exception => e
			error_details = "#{e.class}: #{e}"
			error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
			meta =  {"from" => OPS_EMAIL, "to" => export_resident_params['email']}
			Notifier.system_message("[CRM] Smartrent Residents Export FAILURE", error_details, export_resident_params['email'], meta).deliver_now
		end
	end

	def self.set_residents(export_resident_params)
		residents = []
		if export_resident_params['property_name'] != 'All Properties'
			property_list = Property.where("name = ? and is_smartrent = ? ", export_resident_params['property_name'], true).collect(&:id)
		else
			if export_resident_params['property_state'] == 'All States'
				property_list = Property.where(is_smartrent: true).collect(&:id)
			else
				property_list = Property.where("state = ? and is_smartrent = ?  ", export_resident_params['property_state'], true).collect(&:id)
			end
		end

		Smartrent::ResidentProperty.where(:property_id => property_list).each do |sr|
			next unless sr.resident 
			if export_resident_params['smartrent_status']  == 'All Status'
				residents << sr.resident 
			elsif export_resident_params['smartrent_status']  == 'Active'
				residents << sr.resident if sr.resident.smartrent_status == 'Active' || sr.resident.smartrent_status == 'Inactive'
			else
				residents << sr.resident if sr.resident.smartrent_status == export_resident_params['smartrent_status']
			end 
		end 
		residents = residents.uniq.compact
		return residents
	end

	def self.email_body(export_resident_params, resident_count)
		return <<-MESSAGE
		Your file has been loaded:
		<br>
		- Total smartrent resident count : #{resident_count}
		<br> 
		- Filters:
		<br>
		<br>
		   *  Property Name    : #{export_resident_params['property_name']}
		  <br>
		   *  Propery State    : #{export_resident_params['property_state']}
		  <br>
		   *  Smartrent Status : #{export_resident_params['smartrent_status']}
		  <br>
		<br>
		CRM Help Team
		<br>
		#{HELP_EMAIL}

		MESSAGE
	end

end
