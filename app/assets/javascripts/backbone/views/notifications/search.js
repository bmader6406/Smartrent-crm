Crm.Views.NotificationSearch = Backbone.View.extend({
  template: JST['backbone/templates/notifications/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	if(Crm.collInst.notifications) {
      var self = this;
      _.each(_.keys(Crm.collInst.notifications.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.notifications.queryParams[k] );
      });
    }
      
  	return this;
  },

  onFormSubmit: function(e) {
    e.preventDefault();

    _.each(this.$('form').serializeArray(), function(h){
      Crm.collInst.notifications.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.notifications.getPage(1, {reset: true});
  }
});
