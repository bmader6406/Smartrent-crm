class Ability
  include CanCan::Ability

  def initialize(user)
    # https://github.com/ryanb/cancan/wiki/
    
    user ||= User.new # guest user
    
    alias_action :create, :read, :update, :destroy, :to => :crud
    alias_action :create, :update, :destroy, :to => :cud
    
    if user.has_role? :admin, Property
      # admin can do any actions on any class, resource
      can :manage, :all
      
    else
      # everyone can read property that they have access to
      can :read, Property do |p|
        user.managed_properties.include?(p)
      end

    end

    # dev hack
  
    if Rails.env.development? && false
      can :manage, :all
    end
  
  end
end