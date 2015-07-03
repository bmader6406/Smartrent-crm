Crm.Views.NotificationNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm"
	},
  
  notification: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Notification().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { notification: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {  
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Notification was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Notification was created successfully!');
            
          } else {
            msgbox('Notification was updated successfully!');
            
          }
          
          //must update the notificationObj with the lastest info
          if(App.vars.notificationObj){
            App.vars.notificationObj = response;
          }
          
          self.hideForm();
          Crm.routerInst.navigate('/notifications', true);
        }
      });
    } else {
      var messages = []
      _.each(errors, function(e){ messages.push(e.message)});
      msgbox(messages.join(' <br> '), 'danger');
    }

    ev.stopPropagation();

    return false;
  },

  render: function () {
    var notification = this.notification();

    notification.isCreateNew = this.isCreateNew;

    var form = new Backbone.Form({
      schema: {
        full_name: { 
          title: 'Name',
          validators: ['required']
        }
      },
      fieldsets: [
        {
          tab: 'basic-info',
          legend: "Basic Infomation",
          fields: ["full_name"]
        }
      ],
      data: notification
    }).render();
    
    //+,- icon
    form.$('.accordion').on('show.bs.collapse', function(ev){
      form.$('.panel-heading.expanded').removeClass('expanded');
      $(ev.target).prev().addClass('expanded');
      
    }).on('hide.bs.collapse', function(ev){
      $(ev.target).prev().removeClass('expanded');
    });
    
    setTimeout(function(){
      form.$('.panel-collapse.in').prev().addClass('expanded');
    }, 100);
    
    this.form = form; //for events

    if(this.isCreateNew){
      $(form.el).prepend('<h2>Add New Notification</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add Notification</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).prepend('<h2>Edit Notification</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive">Archive</a>').find('.collapse:first').addClass('in');
    }

    this.$el.html(form.el);

    this.showForm();

    return this;
  },

  showForm: function(){
    App.layout.hide('west');
    $('#notifications .listing').hide();
    $('#notifications .create-update').show().html(this.el);
  },
  
  hideForm: function(){
    if(this.isCreateNew){
      App.layout.show('west');
      $('#notifications .listing').show();
      $('#notifications .create-update').hide();
      
      Crm.routerInst.navigate('/notifications', false);
      
    } else {
      App.layout.show('west');
      Crm.routerInst.navigate('/notifications/' + this.model.get('id'), true);
    }
  },
  
  archive: function (evt) {
    var self = this;

    bootbox.confirm("Sure you want to archive this notification?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Notification was archived successfully");
            Crm.routerInst.navigate('/notifications', true);
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
          }
        });
      }
    });
    
    evt.stopPropagation();

    return false;
  }
});