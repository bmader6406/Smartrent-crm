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

      # Temporary disabled
      #cannot [:cud, :send_email], Resident
      #cannot [:cud], [Ticket, ResidentActivity, Campaign]

    else
      # everyone can read property that they have access to
      can :read, Property do |p|
        user.managed_properties.include?(p)
      end

      if user.has_role? :regional_manager, Property
        can :read, [Property, User, Notification, Resident, Unit, Campaign]
        cannot [:cud, :send_email], Resident
        cannot [:create], [Ticket, ResidentActivity]
        can :list, [Property]

      elsif user.has_role? :property_manager, Property
        can :manage, Smartrent::Reward do |r|
          rewards = user.managed_rewards
          rewards.include?(r) if rewards.present?
        end
        can :manage, [Resident, Unit, Ticket, ResidentActivity, Campaign]
        can :read, [Property, User, Notification]

      elsif user.has_role? :leasing_staff, Property
        can :manage, [Resident, Ticket, ResidentActivity, Campaign]
        can :read, [Property, Notification, Unit]
      end

    end

    # dev hack

    if Rails.env.development? && false
      can :manage, :all
    end

  end
end
