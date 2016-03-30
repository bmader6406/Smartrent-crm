Crm.Views.CampaignSearch = Backbone.View.extend({
  template: JST['backbone/templates/campaigns/search'],
  
  events: {
    'submit form': 'onFormSubmit'
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	if(Crm.collInst.campaigns) {
      var self = this;
      _.each(_.keys(Crm.collInst.campaigns.queryParams), function(k){
        self.$('*[name="'+k+'"]').val( Crm.collInst.campaigns.queryParams[k] );
      });
    }
    
  	return this;
  },

  onFormSubmit: function(e) {
    e.preventDefault();
    
    _.each(this.$('form').serializeArray(), function(h){
      Crm.collInst.campaigns.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.campaigns.getPage(1, {reset: true});
  }
});
