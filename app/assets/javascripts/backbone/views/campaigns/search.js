Crm.Views.CampaignSearch = Backbone.View.extend({
  template: JST['backbone/templates/campaigns/search'],
  
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
      Crm.collInst.campaigns.queryParams[h.name] = h.value;
    });
    
    Crm.collInst.campaigns.getPage(1, {reset: true});
  }
});
