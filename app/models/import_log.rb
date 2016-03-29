class ImportLog < ActiveRecord::Base
  belongs_to :import
  
  
  def stats
    @stats ||= JSON.parse(self[:stats]) rescue {}
  end

  def stats=(data)
    self[:stats] = (@stats || stats).merge(data).to_json
  end
  
end
