Crm.Views.PropertyNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm"
	},
  
  property: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Property().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { property: self.$('form').toJSON() },
      errors = self.form.validate();
    
    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Property was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Property was created successfully!');
            
          } else {
            msgbox('Property was updated successfully!');
          }
          
          //must update the propertyObj with the lastest info
          if(App.vars.propertyObj){
            App.vars.propertyObj = response;
          }
          
          self.hideForm();
          Crm.routerInst.navigate('/properties', true);
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
	  
    bootbox.confirm("Sure you want to archive this property?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Property was archived successfully");
            Crm.routerInst.navigate('/propertiese', true);
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
    var property = this.property(),
      openTime = [],
      closeTime = [];
      
    _.each([5,6,7,8,9,10,11,12,13,14,15,16], function(h){
      _.each(["00","30"], function(m){
        openTime.push((h > 12 ? (h-12) : h ) +":"+m+ (h > 11 ? " PM" : " AM"));
      });
    });
    
    _.each([10,11,12,13,14,15,16,17,18,19,20,21,22,23], function(h){
      _.each(["00","30"], function(m){
        closeTime.push((h > 12 ? (h-12) : h ) +":"+m+ (h > 11 ? " PM" : " AM"));
      });
    });
    
    property.isCreateNew = this.isCreateNew;

    var form = new Backbone.Form({
      schema: {
        name: { 
          validators: [{type: 'required', message: "Name is required"}]
        },
        address_line1: {
          title: 'Address'
        },
        city: 'Text',
        state: 'Text',
        zip: 'Text',
        phone: {
          title: 'Phone Number'
        },
        region_id: {
          type: 'Select',
          title: 'Region',
          options: App.vars.regions
        },
        monday_open_time: {
          title: 'Monday Open Time',
          type: 'Select',
          options: openTime
        },
        monday_close_time: {
          title: 'Monday Open Time',
          type: 'Select',
          options: closeTime
        },
        
        tuesday_open_time: {
          title: 'Tuesday Open Time',
          type: 'Select',
          options: openTime
        },
        tuesday_close_time: {
          title: 'Tuesday Close Time',
          type: 'Select',
          options: closeTime
        },
        
        wednesday_open_time: {
          title: 'Wednesday Open Time',
          type: 'Select',
          options: openTime
        },
        wednesday_close_time: {
          title: 'Wednesday Open Time',
          type: 'Select',
          options: closeTime
        },
        
        thursday_open_time: {
          title: 'Thursday Open Time',
          type: 'Select',
          options: openTime
        },
        thursday_close_time: {
          title: 'Thursday Open Time',
          type: 'Select',
          options: closeTime
        },
        
        friday_open_time: {
          title: 'Friday Open Time',
          type: 'Select',
          options: openTime
        },
        friday_close_time: {
          title: 'Friday Open Time',
          type: 'Select',
          options: closeTime
        },
        
        saturday_open_time: {
          title: 'Saturday Open Time',
          type: 'Select',
          options: openTime
        },
        saturday_close_time: {
          title: 'Saturday Open Time',
          type: 'Select',
          options: closeTime
        },
        
        sunday_open_time: {
          title: 'Sunday Open Time',
          type: 'Select',
          options: openTime
        },
        sunday_close_time: {
          title: 'Sunday Open Time',
          type: 'Select',
          options: closeTime
        },

        email: {
          title: 'Property Email',
          validators: [
            {type: 'required', message: "Property Email is required"},
            {type: 'email', message: "Property Email is not valid"}
          ]
        },
        webpage_url: {
          title: 'Bozzuto.com URL'
        },
        website_url: {
          title: 'Website URL'
        },
        status: {
          title: 'Status',
          editorAttrs: {
            placeholder: 'BMC Current'
          }
        },
        property_number: {
          title: 'Bozzuto Property Number',
          validators: [{type: 'required', message: "Bozzuto Property Number is required"}]
        },
        l2l_property_id: {
          title: 'L2L Property ID',
          validators: [{type: 'required', message: "L2L Property ID is required"}]
        },
        yardi_property_id: {
          title: 'Yardi Property ID',
          validators: [{type: 'required', message: "Yardi Property ID is required"}]
        },
        date_opened: { 
          title: 'Date Opened',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },
        date_closed: { 
          title: 'Date Closed',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },

        region: 'Text',
        regional_manager: {
          title: 'Regional Manager'
        },
        svp: {
          title: 'SVP'
        },
        owner_group: {
          title: 'Owner Group'
        },
        is_smartrent: { 
          title: 'Smartrent Eligible Property',
          type: 'Checkboxes',
          options: [{ val: true, label: 'Yes' }],
          editorAttrs: {
            class: 'list-unstyled'
          }
        }
      },
      template: JST['backbone/templates/properties/form'],
      data: property
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
    
    //datepicker
    form.$('.date-field :text').datepicker({format: 'mm/dd/yyyy'});
    
    this.form = form; //for events

    if(this.isCreateNew){
      $(form.el).prepend('<h2>Add New Property</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add Property</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).prepend('<h2>Edit Property</h2>').append('\
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
    $('#properties .listing').hide();
    $('#properties .create-update').show().html(this.el);
  },
  
  hideForm: function(){
    if(this.isCreateNew){
      App.layout.show('west');
      $('#properties .listing').show();
      $('#properties .create-update').hide();
      
      Crm.routerInst.navigate('/properties', false);
      
    } else {
      App.layout.show('west');
      Crm.routerInst.navigate('/properties/' + this.model.get('id'), true);
    }
  }
});