Crm.Views.Notification = Backbone.View.extend({
  template: JST["backbone/templates/notifications/notification"],
  tagName: 'li',
  
  events: {
    'click .notif': 'showResidentDetail'
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	  this.listenTo(this.model, 'rerender', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  showResidentDetail: function() {
    App.vars.residentObj = null;
    window.location.href = this.model.get("show_path");
  }
  
});
