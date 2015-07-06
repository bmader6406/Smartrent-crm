Crm.Views.NotificationInfo = Backbone.View.extend({
  template: JST["backbone/templates/notifications/info"],
  id: 'notification-info',
  
  events: {
    "click .archive": "archive"
  },
  
  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
	
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  archive: function (evt) {
    var self = this;

    bootbox.confirm("Sure you want to archive this notification?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Notification was archived successfully");
            Crm.routerInst.navigate(App.vars.routeRoot + '/notifications', true);
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
          }
        });
      }
    });
    
    evt.stopPropagation();

    return false;
  }
});
