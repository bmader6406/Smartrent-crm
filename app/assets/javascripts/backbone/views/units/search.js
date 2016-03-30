Crm.Views.UnitSearch = Backbone.View.extend({
  template: JST['backbone/templates/units/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	if(Crm.collInst.units) {
      var self = this;
      _.each(_.keys(Crm.collInst.units.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.units.queryParams[k] );
      });
    }
    
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
