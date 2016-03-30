Crm.Views.UserSearch = Backbone.View.extend({
  template: JST['backbone/templates/users/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	if(Crm.collInst.users) {
      var self = this;
      _.each(_.keys(Crm.collInst.users.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.users.queryParams[k] );
      });
    }
    
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
