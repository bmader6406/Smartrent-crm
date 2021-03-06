class Comment < ActiveRecord::Base

  self.inheritance_column = :_type_disabled
  
  has_one :email
  has_one :call
  has_many :assets
  
  belongs_to :property
  
  has_ancestry
  
  validates :resident_id, :type, :presence => true
  
  default_scope { where(:deleted_at => nil).order("created_at desc") }
  
  before_save :reconcile_email_from
  
  after_create :send_email
  after_create :create_notification
  
  after_update :archive_notification
  
  before_validation :sanitize_xss

  def sanitize_xss
    exclude_list = ["ancestry"]
    SanitizeXss.sanitize(self, exclude_list)
  end

  def resident
    if defined?(@resident) #prevent query executed when record not found
      @resident
    else
      @resident ||= Resident.with(:consistency => :eventual).where(:_id => resident_id).first
    end
  end
  
  def resident_unit_id
    "#{resident_id}_#{unit_id}"
  end
  
  # manual polymorphic
  def author
    if defined?(@author) #prevent query executed when record not found
      @author
    else
      @author ||= author_id ? (class_from_string(author_type).find_by_id(author_id) rescue nil) : nil
    end
  end

  def notification
    if defined?(@notification) #prevent query executed when record not found
      @notification
    else
      @notification ||= Notification.find_by(:comment_id => id)
    end
  end
  
  def eager_load(subject, clzz = nil)
    if subject.kind_of?(Resident) || clzz == "Resident"
      @author = subject
      
    elsif subject.kind_of?(User) || clzz == "User"
      @author = subject
      
    elsif subject.kind_of?(Notification) || clzz == "Notification"
      @notification = subject
    
    end
    
    self
  end

  def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
  
  def has_author?
    author #it is User for now
  end
  
  def email?
    type == "email"
  end
  
  def note?
    type == "note"
  end
  
  def phone?
    type == "phone"
  end
  
  def document?
    type == "document"
  end
  
  private
  
    def reconcile_email_from
      if email?
        self.email.from = property.name.to_s+" <"+ property.email.to_s + ">"
      end
    end

    def send_email
      if email?
        Resque.enqueue(EmailConversationMailer, email.id)
      end
    end
    
    def create_notification
      # create notification if RESIDENT send email to property email
      if email? && author.kind_of?(Resident)
        Notification.create({
          :property_id => property_id,
          :resident_id => resident_id,
          :unit_id => unit_id,
          :state => "pending",
          :subject => email.subject,
          :message => email.message,
          :comment_id => id,
          :created_at => created_at,
          :updated_at => updated_at
        })
      end
    end
    
    def archive_notification
      if deleted_at_changed? && deleted_at && email?
        Notification.where(:property_id => property_id, :comment_id => id).update_all(:deleted_at => Time.now)
      end
    end
  
end
