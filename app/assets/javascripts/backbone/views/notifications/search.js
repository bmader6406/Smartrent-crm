Crm.Views.NotificationSearch = Backbone.View.extend({
  template: JST['backbone/templates/notifications/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
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
