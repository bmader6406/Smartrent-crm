Crm.Views.ActivityNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .cancel": "hideForm"
	},
  
  activity: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Activity().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { activity: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {  
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Activity was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Activity was created successfully!');
            $('.no-histories').hide();
            self.hideForm();
            
          } else {
            msgbox('Activity was updated successfully!');
            self.hideForm();
          }
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
    var activity = this.activity();

    activity.isCreateNew = this.isCreateNew;

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
      data: activity
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
      $(form.el).prepend('<h2>Add New Activity</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add Activity</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).prepend('<h2>Edit Activity</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive">Archive</a>').find('.collapse:first').addClass('in');
    }

    this.$el.html(form.el);

    this.showForm();

    return this;
  },

  showForm: function(){
    $('#form-wrap:visible').html(this.el);
  },
  
  hideForm: function(){

  }
});