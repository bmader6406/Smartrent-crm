Crm.Views.PropertySearch = Backbone.View.extend({
  template: JST['backbone/templates/properties/search'],
  
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
      Crm.collInst.properties.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.properties.getPage(1, {reset: true});
  }
});
