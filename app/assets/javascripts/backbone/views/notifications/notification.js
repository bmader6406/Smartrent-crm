Crm.Views.Notification = Backbone.View.extend({
  template: JST["backbone/templates/notifications/notification"],

  events: {
    "click .acknowledge": "acknowledge",
    "click .reply": "reply",
    "click .send": "send"
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	  this.listenTo(this.model, 'rerender', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  acknowledge: function(ev){
    var notification = this.model;
    return false;
  },
  
  reply: function() {
    var notification = this.model;
    return false;
  },
  
  send: function() {
    var notification = this.model;
    return false;
  }
  
});
