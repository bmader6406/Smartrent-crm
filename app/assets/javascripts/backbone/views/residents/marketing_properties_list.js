Crm.Views.MarketingPropertiesList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled',
  id: 'marketing-properties',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addProperties);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
		this.$el.append(new Crm.Views.MarketingProperty({ model: model }).render().el);
		
    if(model.get('id') == App.vars.propertyId){
      this.$('.resident-box:last').addClass('current');
    }
  },
  
  addProperties: function(){
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
