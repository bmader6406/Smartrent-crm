module NimdaHelper

	def property_list_name
		['All States'] + Property.all.collect(&:state).compact.uniq.sort 
	end

	def property_list_name
		['All Properties'] + Property.all.collect(&:name).compact.uniq.sort 
	end

	def smartrent_status_list
		['All Status'] + Smartrent::Resident.all.collect(&:smartrent_status).uniq
	end

end
