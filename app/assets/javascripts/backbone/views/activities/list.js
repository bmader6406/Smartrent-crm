Crm.Views.ActivitiesList = Backbone.View.extend({
  tagName: 'ul',
  className: 'activities list-unstyled',
  
  events: {

  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addActivities);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model, collection, option) {
    var activityView = new Crm.Views.Activity({ model: model });
		
		if(this.append){
		  this.$el.append(activityView.render().el);
		} else {
		  this.$el.prepend(activityView.render().el);
		}
  },
  
  addActivities: function(){
    this.append = true;
    if(this.firstLoad) this.$el.empty();

    if(this.collection.length == 0 && this.$('.resident-box').length == 0){
      this.$el.html('<div class="well no-histories">No Histories Found</div>');
    } else {
      this.collection.each(this.add, this);
    }
    this.append = false;
    this.firstLoad = false;
  },
  
  remove: function (model) {
    var view = Crm.viewInst[model.toJSON()["id"]];
    if (view) view.remove();
  },
  
  render: function () {
    this.firstLoad = true;
    this.$el.html('Loading...');
    this.collection.fetch({reset: true});
    
  	return this;
  }
});
