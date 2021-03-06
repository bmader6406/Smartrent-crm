Crm.Views.ResidentUnit = Backbone.View.extend({
  template: JST["backbone/templates/residents/unit"],
  tagName: 'li',
  
  events: {
    
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  }
  
});
