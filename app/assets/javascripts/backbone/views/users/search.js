Crm.Views.UserSearch = Backbone.View.extend({
  template: JST['backbone/templates/users/search'],
  
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
      Crm.collInst.users.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.users.getPage(1, {reset: true});
  }
});
