Crm.Views.UnitDetail = Backbone.View.extend({
  template: JST["backbone/templates/units/detail"],
  id: 'unit-detail',
  
  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
	
  render: function () {
  	var self = this;
  	this.$el.html(this.template(this.model.toJSON()));
  	
  	//load unit residents
  	$.get(this.model.get('residents_path'), function(residents){
  	  self.$('#unit-resident-list').html( JST["backbone/templates/units/residents"]({residents: residents}) );
  	}, 'json');
  	
  	return this;
  }
});
