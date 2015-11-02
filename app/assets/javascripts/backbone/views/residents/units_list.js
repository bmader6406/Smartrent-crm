Crm.Views.ResidentUnitsList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled',
  id: 'resident-units',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addUnits);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
    var propertyView = new Crm.Views.ResidentUnit({ model: model });

		this.$el.append(propertyView.render().el);
  },
  
  addUnits: function(){
    this.$el.empty().html('<li class="well well-sm heading">Resident Units</li>');
    
    if(this.collection.length == 0){
      this.$el.html('<div class="well">No Resident Units Found</div>');
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
