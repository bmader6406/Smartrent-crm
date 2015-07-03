Crm.Views.Unit = Backbone.View.extend({
  template: JST["backbone/templates/units/unit"],

  events: {

  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
});
