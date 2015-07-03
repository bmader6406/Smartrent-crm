Crm.Views.UserNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm",
		"click .list-group :checkbox": "countSelectedProperty",
		"change #role": "showHideRegionAppSelect"
	},
  
  user: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.User().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { user: self.$('form').toJSON() },
      errors = self.form.validate();
      
    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('User was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('User was created successfully!');
            
          } else {
            msgbox('User was updated successfully!');
            
          }
          
          //must update the userObj with the lastest info
          if(App.vars.userObj){
            App.vars.userObj = response;
          }
          
          self.hideForm();
          
          App.hideMask();
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
  
  archive: function(evt){
	  var self = this;
	  
	  bootbox.confirm("Sure you want to archive this user?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("User was archived successfully");
            Crm.routerInst.navigate(App.vars.usersPath, true);
            App.hideMask();
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
            App.hideMask();
          }
        });
      }
    });
    
	  evt.stopPropagation();

	  return false;
	},

  render: function () {
    var user = this.user();

    user.isCreateNew = this.isCreateNew;
    
    if(user.isCreateNew) {
      user.role = "property_manager";
    }
    
    var schema = {},
      baseSchema = {
        first_name: { 
          title: 'First Name',
          validators: [{type: 'required', message: 'First Name is required'}]
        },
        last_name: { 
          title: 'Last Name',
          validators: [{type: 'required', message: 'Last Name is required'}]
        },
        email: {
          title: 'Email Address',
          validators: [{type: 'required', message: 'Email is required'}, {type: 'email', message: 'Email is not valid'}]
        },
        role: { 
          type: 'Select',
          options: App.vars.roles,
          validators: [{type: 'required', message: 'Role is required'}]
        },
        password: { 
          type: 'Password',
          validators: [{ type: 'match', field: 'password_confirmation', message: 'Passwords must match!' }]
        },
        password_confirmation: { 
          type: 'Password',
          title: 'Confirm Password'
        }
      };
      
    baseSchema.role.validators.push(function checkProperty(value, formValues) {
      if(_.include(["property_manager"], value)) {
        if(! self.$('input[name*=authorized_property_ids]:checked').val() ) {
          return {
            type: 'required',
            message: 'Authorized For: Property must be selected'
          };
        }
      } else if(_.include(["regional_manager"], value)) {
        if(! self.$('input[name*=authorized_region_ids]:checked').val() ) {
          return {
            type: 'required',
            message: 'Authorized For: Region must be selected'
          };
        }
      }
    });
    
    
    if(user.isCreateNew){
      baseSchema.password.validators.push(function checkPassword(value, formValues) {
        if (value.length < 6) return {
          type: 'required',
          message: 'Password must be at least 6 characters long'
        };
      });
    }
    
    var templateHtml = JST['backbone/templates/users/form'](user);

    $(templateHtml).find('div[data-editors]').each(function(i, div){
      var field = $(div).attr('data-editors');
      schema[field] = baseSchema[field];
    });
    
    var form = new Backbone.Form({
      schema: schema,
      template: _.template(templateHtml),
      data: user
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
    
    // property filter
    form.$('.filter-box :text').fastLiveFilter(form.$('.list-group'), {
      timeout: 200
    });
    
    this.form = form; //for events

    if(this.isCreateNew){
      $(form.el).prepend('<h2>Add New User</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add User</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      if( Helpers.editProfile(user.id) ){
        $(form.el).prepend('<h2>Edit Profile</h2>').append('\
          <button type="submit" class="btn btn-primary btn-lg">Save</button>\
          <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
          
      } else {
        $(form.el).prepend('<h2>Edit User</h2>').append('\
          <button type="submit" class="btn btn-primary btn-lg">Save</button>\
          <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
          <a href="#" class="btn btn-default btn-lg archive">Archive</a>').find('.collapse:first').addClass('in');
      }
      
    }

    this.$el.html(form.el);
    
    this.showForm();
    this.setupPopover();

    return this;
  },

  showForm: function(){
    $('#users .listing').hide();
    $('#users .create-update').show().html(this.el);
  },
  
  hideForm: function(){
    if(this.isCreateNew){
      $('#users .listing').show();
      $('#users .create-update').hide();
      
      Crm.routerInst.navigate(App.vars.usersPath, true);
      
    } else {
      Crm.routerInst.navigate(App.vars.usersPath + "/" + this.model.get('id'), true);
    }
  },
  
  countSelectedProperty: function(){
    this.$('.prop-count').text( this.$('.list-group input:checked').length );
  },
  
  setupPopover: function(){
    var self = this,
      propCount = self.$('.prop-count');
    
    propCount.popover({
      html: true,
      title: 'Selected Property List',
      content: '<div id="auth-list" style="width:300px"></div>',
      trigger: 'hover',
      placement: 'bottom',
      container: 'body',
      delay: { show: 500, hide: 100 }
    });
    
    propCount.on('show.bs.popover', function(){
      var arr = [];
      self.$('.list-group input:checked').each(function(){
        arr.push( "- " + $.trim($(this).parent().text()) );
      });
      
      setTimeout(function(){
        $('#auth-list').html(arr.join("<br>"));
      }, 50);
    });
  },
  
  showHideRegionAppSelect: function(ev){
    if( $(ev.target).val() == "admin"){
      this.$('#region-select, #property-select').slideUp();
      
    } else if( $(ev.target).val() == "regional_manager"){
      this.$('#property-select').slideUp();
      this.$('#region-select').slideDown();
      
    } else {
      this.$('#region-select').slideUp();
      this.$('#property-select').slideDown();
    }
  }
});