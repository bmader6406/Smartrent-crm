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