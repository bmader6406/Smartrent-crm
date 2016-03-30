Crm.Views.PropertySearch = Backbone.View.extend({
  template: JST['backbone/templates/properties/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	if(Crm.collInst.properties) {
      var self = this;
      _.each(_.keys(Crm.collInst.properties.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.properties.queryParams[k] );
      });
    }
    
  	return this;
  },

  onFormSubmit: function(e) {
    e.preventDefault();
    
    _.each(this.$('form').serializeArray(), function(h){
      Crm.collInst.properties.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.properties.getPage(1, {reset: true});
  }
});
