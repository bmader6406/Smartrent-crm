module ResidentsHelper
  
  def total_found(total, noun)
    "#{number_with_delimiter total} #{noun.pluralize(total)}"
  end
  
  def pretty_move_in(date_str)
    date = DateTime.strptime(date_str, '%Y%m%d') rescue nil

    if !date
      date = DateTime.strptime(date_str, '%Y/%m/%d') rescue nil
    end

    if !date
      date = DateTime.strptime(date_str, '%m/%d/%Y') rescue nil
    end

    date.to_s(:utc_date) rescue date_str
  end
  
end