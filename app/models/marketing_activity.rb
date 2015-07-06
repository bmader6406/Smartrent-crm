class MarketingActivity
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :note, :type => String #manual

  field :action, :type => String
  field :subject_id, :type => String
  field :subject_type, :type => String
  field :target_id, :type => String
  field :target_type, :type => String
  field :author_id, :type => String
  field :author_type, :type => String

  field :property_id, :type => String

  embedded_in :resident

  after_create :increase_counter_cache
  after_destroy :decrease_counter_cache
  after_destroy :destroy_dependent

  # e.g: comment, ticket
  def subject
    @subject ||= begin
      s = class_from_string(subject_type).find_by_id(subject_id) rescue nil
    end
  end

  # e.g: url (click), property (subscribe/unsubscribe)
  def target
    @target ||= target_id ? (class_from_string(target_type).find_by_id(target_id) rescue nil) : nil
  end
  
  def author
    @author ||= author_id ? (class_from_string(author_type).find_by_id(author_id) rescue nil) : nil
  end

  def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
  
  def eager_load(subject)
    if subject.kind_of?(Campaign)
      @subject = subject
      
    end
  
    self
  end
  
  protected

    def increase_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"marketing_activities_count" => 1}}, {:multi => true})
    end

    def decrease_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"marketing_activities_count" => -1}}, {:multi => true})
    end
    
    def destroy_dependent
      #pp ">>>>> destroy_dependent"
      if subject.kind_of?(Comment)
        subject.update_attribute(:deleted_at, Time.now)
      end
    end
  
end