Crm.Views.ResidentSearch = Backbone.View.extend({
  template: JST['backbone/templates/residents/search'],
  
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
      Crm.collInst.residents.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.residents.getPage(1, {reset: true});
  }
});
