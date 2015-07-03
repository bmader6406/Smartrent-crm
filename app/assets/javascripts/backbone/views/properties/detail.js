Crm.Views.PropertyDetail = Backbone.View.extend({
  template: JST["backbone/templates/properties/detail"],
  id: 'property-detail',
  
  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
	
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  }
});
