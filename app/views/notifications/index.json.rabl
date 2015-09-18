node(:paging) {|m| 
  {
    :prev => url_for(params),
    :first => url_for(params.merge(:page => 1)),
    :next => @notifications.empty? ? nil : url_for(params.merge(:page => params[:page].to_i + 1))
  }
}

child @notifications, :root => :items, :object_root => false do
  extends "notifications/show"
end