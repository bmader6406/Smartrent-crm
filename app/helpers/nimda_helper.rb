module NimdaHelper

	def property_list_state
		Property.all.collect(&:state).compact.uniq
	end

	def property_list_name
		Property.all.collect(&:name).compact.uniq
	end

	def smartrent_status_list
		Smartrent::Resident.all.collect(&:smartrent_status).uniq
	end

end
