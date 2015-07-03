Crm.Views.NotificationsList = Backbone.View.extend({
  id: 'notifications',
  template: JST['backbone/templates/notifications/list'],
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'add', this.add);
  },

  add: function (model) {
    var notificationView = new Crm.Views.Notification({ model: model });
		
		this.$el.append(notificationView.render().el);
  },
  
  render: function () {
  	//this.$el.html(this.template(this.model.toJSON()));
  	this.$el.html("under construction");
  	return this;
  }
});
