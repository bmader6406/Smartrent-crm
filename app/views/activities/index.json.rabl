node(:paging) {|m| 
  {
    :prev => url_for(params),
    :first => url_for(params.merge(:page => 1)),
    :next => @activities.empty? ? nil : url_for(params.merge(:page => params[:page].to_i + 1))
  }
}

child @activities, :root => :items, :object_root => false do
  extends "activities/show"
end