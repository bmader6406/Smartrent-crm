Crm.Views.UnitSearch = Backbone.View.extend({
  template: JST['backbone/templates/units/search'],
  
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
      Crm.collInst.units.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.units.getPage(1, {reset: true});
  }
});
