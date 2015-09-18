Crm.Views.NotificationsList = Backbone.View.extend({
  template: JST['backbone/templates/notifications/list'],
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'reset', this.addNotifications);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Pendding Message" : " Pendding Messages";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  add: function (model) {
    var notificationView = new Crm.Views.Notification({ model: model });
		
		this.$('#notifications').append(notificationView.render().el);
  },
  
  addNotifications: function(){
    this.$('#notifications').empty();

    if(this.collection.length == 0){
      this.$('#notifications').html('<div class="well">No Messages Found</div>');
    } else {
      this.collection.each(this.add, this);
    }
  },
  
  render: function () {
  	this.$el.html(this.template());
  	
  	this.collection.fetch({reset: true});
  	
  	return this;
  }
});