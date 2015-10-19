class Notification < ActiveRecord::Base
  belongs_to :property
  belongs_to :owner, :class_name => "User"
  belongs_to :last_actor, :class_name => "User"

  has_many :histories, :class_name => "NotificationHistory", :dependent => :destroy
  
  validates :property_id, :resident_id, :state, :message, :presence => true
  validates :last_actor_id, :presence => true, :on => :update
  
  default_scope { where(:deleted_at => nil) }
  
  after_save :create_history
  
  ###
  
  def resident
    @resident ||= resident_id ? Resident.with(:consistency => :eventual).where(:_id => resident_id).first : nil
  end
  
  def eager_load(subject, clzz = nil)
    @resident = subject
    self
  end
  
  private
  
    def create_history
      if state &&  state_changed? #must have this check
        histories.create(:state => state, :actor_id => last_actor_id)
      end
    end
  
end
