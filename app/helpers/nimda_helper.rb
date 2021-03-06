module NimdaHelper

	def property_list_state
		['All States'] + Property.where(is_smartrent: true).collect(&:state).compact.collect(&:strip).uniq.sort 
	end

	def property_list_name
		['All Properties'] + Property.all.where(is_smartrent: true).collect(&:name).compact.collect(&:strip).uniq.sort 
	end

	def smartrent_status_list
		['All Status', 'Active', 'Expired']
		# ['All Status'] + Smartrent::Resident.all.collect(&:smartrent_status).uniq
	end

end
