Crm.Views.UnitInfo = Backbone.View.extend({
  template: JST["backbone/templates/units/info"],
  id: 'unit-info',
  
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

    bootbox.confirm("Sure you want to archive this unit?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Unit was archived successfully");
            Crm.routerInst.navigate(App.vars.routeRoot + '/units', true);
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
