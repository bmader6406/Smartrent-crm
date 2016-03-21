class AddMonthsEarnedToSmartrentRewards < ActiveRecord::Migration
  def change
    add_column :smartrent_rewards, :months_earned, :integer, :default => 0
  end
end
