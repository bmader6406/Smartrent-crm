object @smartrent_resident

node do |n|
  hash = {
    :id => n.id.to_s,
    :email => n.email,
    :smartrent_status_text => n.smartrent_status_text,
    :total_rewards => number_to_currency(n.total_rewards, :precision => 0),
    :total_amount => n.total_rewards,
    :monthly_awards_amount => number_to_currency(n.monthly_awards_amount, :precision => 0),
    :sign_up_bonus => number_to_currency(n.sign_up_bonus, :precision => 0),
    :initial_reward => number_to_currency(n.initial_reward, :precision => 0),
    :first_move_in => (n.first_move_in.to_s(:utc_short_date) rescue nil),
    :total_months => n.total_months.to_i,
    :can_become_buyer => n.can_become_buyer_in_property?(@property),
    :is_admin => current_user.is_admin?,
    :rewards => [],
    
    :reset_rewards_path => reset_rewards_resident_password_path(n),
    :reset_password_path => reset_resident_password_path(n),
    :update_password_path => resident_password_path(n),
    :set_status_path => set_status_resident_password_path(n),
    :set_amount_path => set_amount_resident_password_path(n),
    :become_buyer_path => become_buyer_resident_password_path(n)
  }

  n.rewards.where(type_: [2,3,4]).order("period_start desc, id desc").each do |reward|
    r = {
      :id => reward.id,
      :type_ => Smartrent::Reward.types[reward.type_],
      :period_start => (reward.period_start.to_s(:utc_short_date) rescue nil),
      :period_end => (reward.period_end.to_s(:utc_short_date) rescue nil),
      :property_name => (reward.property.name rescue nil),
      :amount => number_to_currency(reward.amount, :precision => 0),
      :months_earned => reward.months_earned
    }
    
    if r[:type_] == "Monthly Awards"
      r[:period_start] = reward.period_start.strftime("%m/%d/%Y")
      r[:period_end] = reward.period_end.strftime("%m/%d/%Y")
    end
    
    hash[:rewards] << r
  end

  n.rewards.where(type_: [0,1]).order("created_at desc, id desc").each do |reward| 
    r = {
      :id => reward.id,
      :type_ => Smartrent::Reward.types[reward.type_],
      :period_start => (reward.period_start.to_s(:utc_short_date) rescue nil),
      :period_end => (reward.period_end.to_s(:utc_short_date) rescue nil),
      :property_name => (reward.property.name rescue nil),
      :amount => number_to_currency(reward.amount, :precision => 0),
      :months_earned => reward.months_earned
    }

    hash[:rewards] << r
  end
  
  hash
end
