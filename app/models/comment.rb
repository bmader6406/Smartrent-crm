class Comment < ActiveRecord::Base

  self.inheritance_column = :_type_disabled
  
  has_one :email
  has_one :call
  has_many :assets
  
  belongs_to :property
  
  has_ancestry
  
  validates :resident_id, :type, :presence => true
  
  default_scope { where(:deleted_at => nil).order("created_at desc") }
  
  after_create :send_email
  
  def resident
    @resident ||= Resident.with(:consistency => :eventual).where(:_id => resident_id).first
  end
  
  # manual polymorphic
  def author
    @author ||= author_id ? (class_from_string(author_type).find_by_id(author_id) rescue nil) : nil
  end
  
  def eager_load(subject)
    if subject.kind_of?(Resident)
      @author = subject
      
    elsif subject.kind_of?(User)
      @author = subject
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
  
    def send_email
      if email?
        Resque.enqueue(EmailConversationMailer, email.id)
      end
    end
  
end