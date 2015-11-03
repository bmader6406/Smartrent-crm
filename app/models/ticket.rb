class Ticket < ActiveRecord::Base

  STATUSES = ["Open", "Closed", "On Hold"]
  URGENCIES = ["Low", "High"]
  
  belongs_to :property
  belongs_to :category
  belongs_to :assigner, :class_name => "User"
  belongs_to :assignee, :class_name => "User"
  
  has_many :assets, :dependent => :destroy
  
  validates :description, :status, :urgency, :category_id, :assigner_id, :assignee_id, :presence => true
  
  attr_accessor :author, :action
  
  default_scope { where(:deleted_at => nil).order("created_at desc") }
  
  after_save :create_activity, :if => lambda { |t| t.resident }
  
  def resident
    @resident ||= Resident.with(:consistency => :eventual).where(:_id => resident_id).first
  end

  def eager_load(subject, clzz = nil)
    @resident = subject
    self
  end
  
  private
  
    def create_activity
      ticket_action = nil
      
      if action == "new_ticket"
        ticket_action = "new_ticket"
        
      elsif status_changed?
        ticket_action = case status
          when "open"
            "reopened_ticket"
            
          when "closed"
            "closed_ticket"
            
          when "on hold"
            
            "on_hold_ticket"
          else
            status
        end
      end
      
      pp ">>> ticket status: #{status}, #{ticket_action}"
      
      if ticket_action
        resident.activities.create({
          :action => ticket_action,
          :author_id => author.id,
          :author_type => author.class.to_s,
          :subject_id => id,
          :subject_type => self.class.to_s,
          :property_id => property_id,
          :unit_id => unit_id
        })
      end
    end
end