# for some reason, it does not work
object @status

node do |n|
  {
    :status => n[:status],
    :status_date => n[:status_date].to_s(:utc_date),
    :move_in => pretty_move_in(n[:move_in]),
    :move_out => pretty_move_in(n[:move_out])
  }
end