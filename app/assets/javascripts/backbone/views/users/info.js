Crm.Views.UserInfo = Backbone.View.extend({
  template: JST["backbone/templates/users/info"],
  id: 'user-info',
  
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

    bootbox.confirm("Sure you want to archive this user?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("User was archived successfully");
            Crm.routerInst.navigate(App.vars.usersPath, true);
            App.hideMask();
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
            App.hideMask();
          }
        });
      }
    });
    
    evt.stopPropagation();

    return false;
  }
});
