Crm.Views.TicketSearch = Backbone.View.extend({
  template: JST['backbone/templates/tickets/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	this.$('.date-field :text').datepicker({format: 'yyyy-mm-dd'});
  	
  	return this;
  },

  onFormSubmit: function(e) {
    e.preventDefault();
    
    _.each(this.$('form').serializeArray(), function(h){
      Crm.collInst.tickets.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.tickets.getPage(1, {reset: true});
  }
});
