Crm.Views.PropertyInfo = Backbone.View.extend({
  template: JST["backbone/templates/properties/info"],
  id: 'property-info',
  
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

    bootbox.confirm("Sure you want to archive this property?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Property was archived successfully");
            Crm.routerInst.navigate('/properties', true);
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
