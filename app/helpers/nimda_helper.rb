module NimdaHelper

	def property_list_state
		['All States'] + Property.all.collect(&:state).compact.collect(&:strip).uniq.sort 
	end

	def property_list_name
		['All Properties'] + Property.all.collect(&:name).compact.collect(&:strip).uniq.sort 
	end

	def smartrent_status_list
		['All Status'] + Smartrent::Resident.all.collect(&:smartrent_status).uniq
	end

end
