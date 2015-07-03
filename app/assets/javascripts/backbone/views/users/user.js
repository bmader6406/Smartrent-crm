App.Views.User = Backbone.View.extend({
  template: JST["backbone/templates/users/user"],

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
