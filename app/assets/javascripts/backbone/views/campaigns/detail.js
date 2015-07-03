Crm.Views.CampaignDetail = Backbone.View.extend({
  template: JST["backbone/templates/campaigns/detail"],
  id: 'campaign-detail',
  
  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
	
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  }
});
