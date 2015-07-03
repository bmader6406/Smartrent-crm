Crm.Views.ResidentNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm",
		"change #vehicles_count": "showVehicles"
	},
	
  resident: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Resident().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { resident: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Resident was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Resident was created successfully!');
            self.hideForm();
            
          } else {
            msgbox('Resident was updated successfully!');
            
            //manual trigger change event of model. TODO: check backbone model param root
            if(model.changed.resident){
              //must update the residentObj with the lastest info
              if(App.vars.residentObj){
                App.vars.residentObj = response;
              }
              self.model.set(model.changed.resident, {silent: true});
            }
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
  
  archive: function(evt){
	  var self = this;
	  
	  bootbox.confirm("Sure you want to archive this resident?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Resident was archived successfully");
            Crm.routerInst.navigate('/residents', true);
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
          }
        });
      }
    });

	  return false;
	},

  render: function () {
    var resident = this.resident();
    
    if(resident.property){
      $.extend(resident, resident.property);
    }
    var unitOptions = App.vars.propertyUnits || [];
    
    if(Crm.collInst.units && Crm.collInst.units.toJSON().length >= unitOptions.length){
      unitOptions = [];
      _.each(Crm.collInst.units.toJSON(), function(u){
        unitOptions.push({val: u.id, label: u.code});
      });
    }
    
    var schema = {},
      baseSchema = {
        property_id: { 
          type: 'Select',
          title: 'Property',
          validators: [{type: 'required', message: 'Property is required'}],
          options: App.vars.properties
        },
        unit_id: { 
          type: 'Select',
          title: 'Unit',
          validators: [{type: 'required', message: 'Unit is required'}],
          options: unitOptions
        },
        full_name: { 
          title: 'Name',
          validators: [{type: 'required', message: 'Name is required'}]
        },
        email: {
          title: 'Email Address',
          validators: [{type: 'required', message: 'Email is required'}, {type: 'email', message: 'Email is not valid'}]
        },
        primary_phone: {
          title: 'Primary Phone',
          validators: [{type: 'required', message: 'Primary Phone is required'}]
        },

        status: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Status is required'}],
          options: App.vars.metricOptions["resident_status"]
        },

        type: { 
          type: 'Select',
          validators: [{type: 'required', message: 'Type is required'}],
          options: App.vars.metricOptions["resident_type"]
        },
        street: 'Text',
        city: 'Text',
        state: { 
          type: 'Select',
          options: App.vars.states
        },
        zip: 'Text',
        gender: { 
          type: 'Select',
          options: App.vars.metricOptions["gender"]
        },
        birthday: { 
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },
        last4_ssn: {
          title: 'Lass 4 of Social Security #',
          validators: [{type: "regexp", regexp: /^\d{4}$/, message: 'Please enter 4 digits'}]
        },
        cell_phone: {
          title: 'Cell Phone'
        },
        home_phone: {
          title: 'Home Phone'
        },
        work_phone: {
          title: 'Work Phone'
        },
        signing_date: {
          title: 'Contact Signing Date',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },
        move_in: {
          title: 'Move-in Date',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },
        move_out: { 
          title: 'Move-out Date',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          }
        },

        household_size: {
          type: 'Select',
          title: 'Household Size',
          options: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        },
        household_status: {
          type: 'Select',
          title: 'Household Satus',
          options: App.vars.metricOptions["household_status"]
        },
        moving_from: {
          type: 'Select',
          title: 'Moving From',
          options: App.vars.metricOptions["moving_from"]
        },
        pets_count: { 
          type: 'Select',
          title: 'Pets Count',
          options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        },
        pet_type:{
          type: 'Select',
          title: 'Pet Type',
          options: App.vars.metricOptions["pet"]
        },
        pet_breed: {
          title: 'Pet Breed'
        },
        pet_name: {
          title: 'Pet Name'
        },
        occupation_type: {
          type: 'Select',
          title: 'Occupation Type',
          options: App.vars.metricOptions["occupation_type"]
        },
        employer: 'Text',
        employer_city: {
          title: 'Employer City'
        },
        employer_state: { 
          type: 'Select',
          title: 'Employer State',
          options: App.vars.states
        },
        annual_income: {
          title: 'Annual Income',
          validators: [{type: 'number', message: 'Must be a number'}]
        },
        minutes_to_work: {
          type: 'Select',
          title: 'Minutes To Work',
          options: App.vars.metricOptions["minutes_to_work"]
        },
        transportation_to_work: {
          type: 'Select',
          title: 'Transportation To Work',
          options: App.vars.metricOptions["transportation_to_work"]
        },
        vehicles_count: { 
          type: 'Select',
          title: 'Number Of Vehicles',
          options: [0, 1, 2, 3, 4, 5]
        },
        vehicle1: {
          title: 'Vehicle 1 Make/Model'
        },
        license1: {
          title: 'Vehicle 1 License Plate'
        },
        vehicle2: {
          title: 'Vehicle 2 Make/Model'
        },
        license2: {
          title: 'Vehicle 2 License Plate'
        },
        badge_number: {
          title: 'Badge #'
        }
      };
      
    
    var templateHtml = JST['backbone/templates/residents/form']({isCreateNew: this.isCreateNew});
    
    $(templateHtml).find('div[data-fields]').each(function(i, div){
      $.each( $(div).attr('data-fields').split(','), function(j, field){
        schema[field] = baseSchema[field];
      });
    });
    
    $(templateHtml).find('div[data-editors]').each(function(i, div){
      var field = $(div).attr('data-editors');
      schema[field] = baseSchema[field];
    });
    
    var form = new Backbone.Form({
      schema: schema,
      template: _.template( templateHtml ),
      data: resident
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
      $(form.el).prepend('<h2>Add New Resident</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Add Resident</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).prepend('<h2>Edit Resident</h2>').append('\
        <button type="submit" class="btn btn-primary btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive">Archive</a>').find('.collapse:first').addClass('in');
    }
    
    this.$el.html(form.el);
    
    if( parseInt(resident.vehicles_count) > 0) this.$('.vehicle-detail').show();
    
    this.showForm();
    
    return this;
  },
  
  showForm: function(){
    App.layout.hide('west');
    $('#residents .listing').hide();
    $('#residents .create-update').show().html(this.el);
  },
  
  hideForm: function(){
    if(this.isCreateNew){
      App.layout.show('west');
      $('#residents .listing').show();
      $('#residents .create-update').hide();
      
      Crm.routerInst.navigate('/residents', false);
      Crm.collInst.residents.fetch();
      
    } else {
      App.layout.show('west');
      Crm.routerInst.navigate('/residents/' + this.model.get('id'), true);
    }
    
    return false;
  },
  
  showVehicles: function(ev){
    if ($(ev.target).val() == 0){
      this.$('.vehicle-detail').hide();
    } else {
      this.$('.vehicle-detail').show();
    }
  }
});