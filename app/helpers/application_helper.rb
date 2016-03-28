module ApplicationHelper
  
  def bootstrap_class_for flash_type
    { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-success" }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible", id: "flash", role: 'alert') do
        concat(content_tag(:button, class: 'close', data: { dismiss: 'alert' }) do
          concat content_tag(:span, '&times;'.html_safe, 'aria-hidden' => true)
          concat content_tag(:span, 'Close', class: 'sr-only')
        end)
        concat message
      end)
    end
    
    concat javascript_tag "
      $(function(){
        var flash = $('#flash:hidden');
        if(flash.hasClass('alert-success')){
          msgbox(flash.find('button').remove().end().text());
        }
      })
    "
    
    nil
  end
  
  def ability_to_array(a)
    rules = a.instance_variable_get("@rules")
    if rules
      rules.collect do |rule| 
        rule.instance_eval do
          {
            :base_behavior => @base_behavior,
            :subjects => @subjects.map(&:to_s),
            :actions => @actions.map(&:to_s),
            :conditions => @conditions
          }
        end
      end
    else
      []
    end
  end
  
  def ticket_assignees
    arr = [{:val => current_user.id.to_s, :label => current_user.full_name}]
    
    User.all.each do |user|
        next if current_user == user
        arr << {:val => user.id.to_s, :label => user.full_name}
    end
    
    arr.uniq
  end
  
  def metric_options
    #TODO: make it editable
    {
      "resident_status" => {
        "" => "--Select Status--",
        "Current" => "Current",
        "Future" => "Future",
        "Past" => "Past",
        "Notice" => "Notice"
      },
      "resident_type" => {
        "" => "--Select Type--",
        "Email" => "Email",
        "Phone" => "Phone",
        "Walk-in" => "Walk-in"
      },
      "occupation_type" => [
        "None",
        "Admin/Support Staff",
        "Blue Collar",
        "Corporate",
        "Education",
        "Finance/Accounting",
        "Full-Time Homemaker",
        "Government Employee",
        "Government Funding",
        "Medical",
        "Military",
        "Minor Child",
        "Professional",
        "Public Service",
        "Real Estate",
        "Retail Trade",
        "Retired",
        "Sales",
        "Self-Employed",
        "Student",
        "Technology",
        "Unemployed"
      ],
      "minutes_to_work"=> [
        "",
        "1-15 minutes",
        "16-30 minutes",
        "31-45 minutes", 
        "46-60 minutes",
        "61+ minutes",
        "Child",
        "Corporate Apartment",
        "Does not work",
        "Work from home"
      ],
      "household_status" => {
        "" => "--Select House Hold Status--",
        "Corporate" => "Corporate",
        "Married" => "Married",
        "Married w/ Child(ren)" => "Married w/ Child(ren)",
        "Married w/ Roommate" => "Married w/ Roommate" ,
        "Roommates" => "Roommates",
        "Roommates w/ Child(ren)" => "Roommates w/ Child(ren)",
        "Separated/Divorced" => "Separated/Divorced",
        "Separated/Divorced w/ Child(ren)" => "Separated/Divorced w/ Child(ren)",
        "Single" => "Single",
        "Single w/ Child(ren)" => "Single w/ Child(ren)"
      },
      "pet"=>{
        "" => "--Select Pets--",
        "Dog" => "Dog",
        "Cat" => "Cat",
        "Others" => "Others",
        "None" => "None"
      },
      "gender"=>{
        "" => "--Select Gender--",
        "Male" => "Male",
        "Female" => "Female",
        "Other" => "Other"
      },
      "transportation_to_work" => {
        "" => "--Select Transportation to Work--",
        "Carpool" => "Carpool",
        "Does Not Work" => "Does Not Work",
        "Own Vehicle" => "Own Vehicle",
        "Walk" => "Walk",
        "Public" => "Public"
      },
      "moving_from" => {
        "" => "--Select Moving From--",
        "Apartment" => "Apartment",
        "Centreville" => "Centreville",
        "College" => "College",
        "House" => "House",
        "Parents" => "Parents"
      },
      "occupant_type" => {
        "" => "--Select Occupant Type--",
        "Type 1" => "Type 1",
        "Type 2" => "Type 2",
        "Type 3" => "Type 3",
        "Type 4" => "Type 4",
        "Type 5" => "Type 5"
      },
      "relationship" => {
        "" => "--Select Relationship--",
        "Relationship 1" => "Relationship 1", 
        "Relationship 2" => "Relationship 2", 
        "Relationship 3" => "Relationship 3"
      }
    }
  end
  
  def sr_page?
    request.path.include?("/sr/") || request.host.include?("smartrent")
  end
  
  def pending_messages
    @pending_messages ||= begin
      if @property
        current_user.notifications.where(:property_id => @property.id, :state => "pending").all
      else
        current_user.notifications.where(:state => "pending").all
      end
    end
  end
  
end


class BootstrapLinkRenderer < ::WillPaginate::ActionView::LinkRenderer
  protected

  def html_container(html)
    tag :ul, html, container_attributes
  end

  def page_number(page)
    tag :li, link(page, page, :rel => rel_value(page)), :class => ('active' if page == current_page)
  end

  def gap
    tag :li, link(super, '#'), :class => 'disabled'
  end

  def previous_or_next_page(page, text, classname)
    tag :li, link(text, page || '#'), :class => [classname[0..3], classname, ('disabled' unless page)].join(' ')
  end
end

def page_navigation_links(pages, param_name = "page" )
  will_paginate(pages, :class => 'pagination', :inner_window => 2, :outer_window => 0, :param_name => param_name,
    :renderer => BootstrapLinkRenderer, :previous_label => '&larr;'.html_safe, :next_label => '&rarr;'.html_safe)
end
