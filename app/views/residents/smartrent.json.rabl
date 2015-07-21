object @smartrent_resident

node do |n|
  hash = {
    :id => n.id.to_s,
    :email => n.email,
    :status => n.status,
    :status_text => n.smartrent_status_text,
    :total_rewards => number_to_currency(n.total_rewards),
    :monthly_awards_amount => number_with_delimiter(n.monthly_awards_amount),
    :sign_up_bonus_ => number_with_delimiter(n.sign_up_bonus_),
    :initial_reward => number_with_delimiter(n.initial_reward),
    :move_in_date => (n.move_in_date.to_s(:year_month_day) rescue nil),
    :total_months => n.total_months.to_i,
    :type_ => n.type_,
    :rewards => [],
    
    :reset_password_path => reset_resident_password_path(n),
    :update_password_path => resident_password_path(n),
    :set_status_path => set_status_resident_password_path(n)
  }

  n.rewards.each do |reward|
    hash[:rewards] << {
      :type_ => Smartrent::Reward.types[reward.type_],
      :period_start => (reward.period_start.to_s(:year_month_day) rescue nil),
      :period_end => (reward.period_end.to_s(:year_month_day) rescue nil),
      :property_name => (reward.property.name rescue nil),
      :amount => number_to_currency(reward.amount)
    }
  end
  
  hash
end
