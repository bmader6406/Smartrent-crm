Crm.Views.ResidentRoommatesList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled roommates',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addRoommates);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
    var roommateView = new Crm.Views.Roommate({ model: model });
		this.$el.append(roommateView.render().el);
  },
  
  addRoommates: function(){
    this.$el.empty();
    
    if(this.collection.length == 0){
      this.$el.html('<div class="well">No Roommates Found</div>');
    } else {
      this.collection.each(this.add, this);
    }
  },
  
  remove: function (model) {
    var view = Crm.viewInst[model.toJSON()["id"]];
    if (view) view.remove();
  },
  
  render: function () {
    this.collection.fetch({reset: true});
    
  	return this;
  }
});
