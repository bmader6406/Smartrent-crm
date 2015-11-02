//for resident roommates (no new/edit form for /roommates)
Crm.Views.RoommateNewOrUpdate = Backbone.View.extend({
  
  // don't share the same el: 'ID'
  
  events:	{
		"submit .roommate-form": "submit",
		"click .archive": "archive",
		"click .cancel": "cancel"
	},
  
  roommate: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Roommate().toJSON();
  },
  
  cancel: function(){
    if(this.isCreateNew){
      this.$el.slideUp();
      $(this.form.el).resetForm();
      
    } else {
      this.model.trigger('rerender');
    }
    
    return false;
  },
  
  submit: function(){
    var errors = this.form.validate(),
      messages = [];
    
    if(errors) {
      _.each(errors, function(e){ messages.push(e.message)});
      msgbox(messages.join(' <br> '), 'danger');
      return false;
    }
    
    if( this.uploadForm && this.$('.files tr:visible, .import-files tr:visible').length > 0 ) { //has upload file
      this.uploadForm.upload();
      
    } else { //otherwise, submit form
      this.createOrUpdate();
    }
    
    return false;
  },
  
  createOrUpdate: function () {
    //disable "sub-form" inputs
    if(this.uploadForm) this.uploadForm.$('input,textarea,select').attr('disabled', true);
    
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { roommate: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {
      self.$el.mask('Please wait...');
      
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Roommate was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Roommate was created successfully!');
            
          } else {
            msgbox('Roommate was updated successfully!');
            
          }
          
          //must update the roommateObj with the lastest info
          if(App.vars.roommateObj){
            App.vars.roommateObj = response;
          }
          
          if(Crm.collInst.residentRoommates) Crm.collInst.residentRoommates.fetch({reset: true});
          
          $(self.form.el).resetForm();

          self.$el.hide();
        },
        
        complete: function(){
          self.$el.unmask();
        }
      });
    } else {
      var messages = []
      _.each(errors, function(e){ messages.push(e.message)});
      msgbox(messages.join(' <br> '), 'danger');
      
      self.$el.unmask();
    }
    
    //no ev var!

    return false;
  },
  
  archive: function(evt){
	  var self = this;
	  
    bootbox.confirm("Sure you want to archive this roommate?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Roommate was archived successfully");
            
            $(self.form.el).resetForm();
            self.$el.hide();
            
            Crm.collInst.residentRoommates.fetch({reset: true});
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
    var roommate = this.roommate();
    
    if(roommate.property){
      $.extend(roommate, roommate.property);
    }
    
    if(this.isCreateNew){
      if(this.resident.get('property')){
        roommate.unit_id = this.resident.get('property').unit_id; //assign on new form view
      }
    }
    
    var form = new Backbone.Form({
      schema: {
        unit_id: { // prefill unit_id, don't add validation 
          type: 'Hidden'
        },
        last_name: {
          title: 'Last Name',
          validators: [{type: 'required', message: 'Last Name is required'}]
        },
        first_name: {
          title: 'First Name',
          validators: [{type: 'required', message: 'First Name is required'}]
        },
        lessee: { 
          type: 'Checkboxes',
          options: [{ val: true}],
          editorAttrs: {
            class: 'list-unstyled'
          }
        },
        occupant_type: {
          type: 'Select',
          title: 'Occupant Type',
          options: App.vars.metricOptions["occupant_type"]
        },
        email: {
          title: 'Email',
          validators: [{type: 'required', message: 'Email is required'}, {type: 'email', message: 'Email is not valid'}]
        },
        alt_email: {
          title: 'Alt. Email'
        },
        ssn: {
          title: 'SSN#'
        },
        move_in: {
          title: 'Move-in Date',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          },
          validators: [{type: 'required', message: 'Move In is required'}]
        },
        move_out: { 
          title: 'Move-out Date',
          fieldClass: 'date-field',
          editorAttrs: {
            placeholder: 'mm/dd/yyyy'
          },
          validators: [{type: 'required', message: 'Move Out is required'}]
        },
        relationship: {
          type: 'Select',
          options: App.vars.metricOptions["relationship"]
        },
        office_phone: {
          title: 'Office Phone'
        },
        home_phone: {
          title: 'Home Phone'
        },
        fax: 'Text',
        mobile: 'Text',
        
        vehicle1: {
          title: 'Car Model/Color'
        },
        
        license1: {
          title: 'License #'
        },
        
        employer: 'Text',
        work_phone: {
          title: 'Work Phone'
        },
        work_hour: {
          title: 'Work Hours'
        },
        other1: 'Text',
        other2: 'Text',
        other3: 'Text',
        other4: 'Text',
        other5: 'Text',
        arc_check: { 
          type: 'Checkboxes',
          options: [{ val: true, label: 'I choose to opt out ARC check conversions, do not scan my checks' }],
          editorAttrs: {
            class: 'list-unstyled'
          }
        }
      },
      template: JST['backbone/templates/roommates/form'],
      data: roommate,
      templateData: roommate
    }).render();

    this.form = form; //for events
    
    //datepicker
    form.$('.date-field :text').datepicker({format: 'mm/dd/yyyy'});
    
    if(this.isCreateNew){
      $(form.el).append('\
        <button type="submit" class="btn btn-success btn-lg">Add Roommate</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>');
    } else {
      $(form.el).append('\
        <button type="submit" class="btn btn-success btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive">Archive</a>');
    }

    this.$el.html(form.el);

    return this;
  }
});