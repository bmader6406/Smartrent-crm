module UnsubscribesHelper
  def list_name
    @property.name
  end
  
  def unsubscribe_all?
    true
  end
end
