Crm.Views.QuickNotificationsList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled notifications',
  
  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'reset', this.addNotifications);
    this.listenTo(this.collection, 'add', this.add);
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      pendingCount =  $('#pending-count'),
      icon = pendingCount.parent().find('> .fa');

    if(total > 0){
      pendingCount.text("("+ total +")");
      icon.removeClass('fa-bell-o').addClass('fa-bell');
    } else {
      pendingCount.text("");
      icon.removeClass('fa-bell').addClass('fa-bell-o');
    }
  },

  add: function (model) {
    var notificationView = new Crm.Views.Notification({ model: model });
		this.$el.append(notificationView.render().el);
  },
  
  addNotifications: function(){
    this.$el.empty();
    
    if(this.collection.length == 0){
      this.$el.html('<li><div class="notif">No Messages Found</div></li>');
    } else {
      this.collection.each(this.add, this);
    }
  },
  
  render: function () {
    this.collection.fetch({reset: true});
    return this;
  }
});