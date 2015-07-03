Crm.Views.ResidentPropertiesList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled',
  id: 'resident-properties',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addProperties);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
    var propertyView = new Crm.Views.ResidentProperty({ model: model });

		this.$el.append(propertyView.render().el);
  },
  
  addProperties: function(){
    this.$el.empty().html('<li class="well well-sm heading">Properties</li>');
    
    if(this.collection.length == 0){
      this.$el.html('<div class="well">No Properties Found</div>');
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
