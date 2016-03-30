Crm.Views.TicketSearch = Backbone.View.extend({
  template: JST['backbone/templates/tickets/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	this.$('.date-field :text').datepicker({format: 'yyyy-mm-dd'});
  	
  	if(Crm.collInst.tickets) {
      var self = this;
      _.each(_.keys(Crm.collInst.tickets.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.tickets.queryParams[k] );
      });
    }
  	
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
