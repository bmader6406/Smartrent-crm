Crm.Views.UnitNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm"
	},
  
  unit: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Unit().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { unit: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {  
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Unit was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Unit was created successfully!');
            
          } else {
            msgbox('Unit was updated successfully!');
            
          }
          
          //must update the unitObj with the lastest info
          if(App.vars.unitObj){
            App.vars.unitObj = response;
          }
          
          self.hideForm();
          Crm.routerInst.navigate(App.vars.routeRoot + '/units', true);
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
	  
	  bootbox.confirm("Sure you want to archive this unit?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Unit was archived successfully");
            Crm.routerInst.navigate(App.vars.routeRoot + '/units', true);
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
          }
        });
      }
    });

	  evt.stopPropagation();

	  return false;
	},

  render: function () {
    var unit = this.unit();

    unit.isCreateNew = this.isCreateNew;

    var form = new Backbone.Form({
      schema: {
        code: {
          title: 'Code',
          validators: [{type: 'required', message: 'Code is required'}]
        },
        bed: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Bed is required'}],
          options: [1, 2, 3, 4, 5, 6, 7, 8, 9]
        },
        bath: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Bath is required'}],
          options: [1, 2, 3, 4, 5, 6, 7, 8, 9]
        },
        sq_ft: {
          title: 'Sq. Ft.',
          validators: [{type: 'required', message: 'Sq. Ft. is required'}]
        },
        status: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Status is required'}],
          options: ['Active', 'Inactive']
        },
        rental_type: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Rental Type is required'}],
          options: ["Residential", "Affordable"]
        },
        description: 'TextArea'
      },
      fieldsets: [
        {
          tab: 'unit-info',
          legend: "Unit Infomation",
          fields: ["code", "bed", "bath", "sq_ft", "status", "rental_type", "description"]
        }
      ],
      data: unit
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
      $(form.el).prepend('<h2>Add New Unit</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add Unit</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).prepend('<h2>Edit Unit</h2>').append('\
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
    $('#units .listing').hide();
    $('#units .create-update').show().html(this.el);
  },
  
  hideForm: function(){
    if(this.isCreateNew){
      App.layout.show('west');
      $('#units .listing').show();
      $('#units .create-update').hide();
      
      Crm.routerInst.navigate(App.vars.routeRoot + '/units', false);
      
    } else {
      App.layout.show('west');
      Crm.routerInst.navigate(App.vars.routeRoot + '/units/' + this.model.get('id'), true);
    }
  }
});