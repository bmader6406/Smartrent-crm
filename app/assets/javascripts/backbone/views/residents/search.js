Crm.Views.ResidentSearch = Backbone.View.extend({
  template: JST['backbone/templates/residents/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
    this.$el.html(this.template());
    
    if(Crm.collInst.residents) {
      var self = this;
      _.each(_.keys(Crm.collInst.residents.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.residents.queryParams[k] );
      });
    }
    
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
