Crm.Views.QuickNotificationsList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled notifications',
  
  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'reset', this.addNotifications);
    this.listenTo(this.collection, 'add', this.add);
    
    this.autoRefresh();
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
  
  autoRefresh: function () {
    var self = this,
      notifyDiv = $('#notify');
      
    if (this.refreshTimer) clearInterval(this.refreshTimer);

    this.refreshTimer = setInterval(function () {
      var firstNotif = self.collection.at(0);
      
      if(firstNotif) {
        $.getJSON(App.vars.notificationsPath + "/poll", {time: firstNotif.get('created_at') }, function(data){
          
          if( data.length > 0 ){
            if( !$.cookie("notif_sound_off") ) {
              var aSound = document.createElement('audio');
               aSound.setAttribute('src', '/beep.wav');
               aSound.play();
            }

            $.each(data, function(i, n){
              var msg = "<a class='new-notif' href='"+ n.show_path +"'>" +
                            "<b>" + n.resident_name + " | " + n.subject + "</b>" + 
                            "<br>" + Helpers.truncate(Helpers.sanitize(n.message), 50) + 
                            "<br> <small>" + Helpers.timeOrTimeAgo(n.created_at) + "</small> " +
                         "</a>";

              notifyDiv.notify({
                type: "success",
                message: { html: msg },
                fadeOut: { enabled: false }
              }).show();
            });
          }
          
          self.collection.fetch({reset: true});
        });
      }
    }, 30000 ); //refresh every 30 seconds
  },
  
  render: function () {
    this.collection.fetch({reset: true});
    return this;
  }
});