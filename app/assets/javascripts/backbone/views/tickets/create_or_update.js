//for resident tickets (no new/edit form for /tickets)
Crm.Views.TicketNewOrUpdate = Backbone.View.extend({

  // don't share the same el: 'ID'

  events:	{
		"submit .ticket-form": "uploadThenSubmit",
		"click .archive": "archive",
		"click .cancel": "cancel",
		"click .show-options": "showOptions",
		"click .add-file": "showUploadForm",
		"click .assets .remove": "removeAsset"
	},

  ticket: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Ticket().toJSON();
  },

  cancel: function(){
    if(this.isCreateNew){
      $('#toolbar .btn.selected').click();
      $(this.form.el).resetForm();

    } else {
      this.model.trigger('rerender');
    }

    this.clearUploadForm();

    return false;
  },

  showOptions: function(ev){
    $(ev.target).hide();
    this.$('.options').slideDown();
    return false;
  },

  showUploadForm: function(ev){
    if( !this.uploadForm ){
      this.uploadForm = new Crm.Views.TicketUploadForm();
      this.uploadForm.ticket = this.model;
      this.uploadForm.ticketFormView = this;

      this.$('.add-file').before( this.uploadForm.render().el );
    } else {
      this.uploadForm.$el.slideDown();
    }

    this.$('.add-file').hide();

    return false;
  },

  clearUploadForm: function(){
    this.uploadForm = null;
    this.$('#upload-form').remove();
  },

  uploadThenSubmit: function(){
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

  removeAsset: function(e) {
    var link = $(e.target).parent(),
      field = this.$('#remove-asset-ids');

    field.val(field.val() + "," + link.attr('data-id'));
    link.fadeOut();

    return false;
  },

  createOrUpdate: function () {
    //disable "sub-form" inputs
    if(this.uploadForm) this.uploadForm.$('input,textarea,select').attr('disabled', true);

    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { ticket: self.$('form').toJSON() },
      errors = self.form.validate();

    if( !errors ) {
      self.$el.mask('Please wait...');

      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Ticket was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Ticket was created successfully!');
            if (App.vars.unit.isTicket = true) {
              App.vars.unit.successCallBack();
            }

          } else {
            msgbox('Ticket was updated successfully!');

          }

          //must update the ticketObj with the lastest info
          if(App.vars.ticketObj){
            App.vars.ticketObj = response;
          }

          if(Crm.collInst.residentTickets) Crm.collInst.residentTickets.fetch();
          if(Crm.collInst.residentActivities) Crm.collInst.residentActivities.fetch();

          $(self.form.el).resetForm();
          self.clearUploadForm();

          self.$el.slideUp();

          $('#toolbar .btn').removeClass('selected');
        },

        complete: function(){
          self.$el.unmask();
          if(self.uploadForm) self.uploadForm.$('input,textarea,select').removeAttr('disabled');
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

    bootbox.confirm("Sure you want to archive this ticket?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Ticket was archived successfully");
            Crm.routerInst.navigate(App.vars.routeRoot + '/tickets', true);
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
    var ticket = this.ticket();

    if(this.isCreateNew){
      ticket.status = "open";
      ticket.urgency = "low";
      ticket.can_enter = "1";
      ticket.resident_id = this.resident.get('id'); //assign on new form view
    }

    if(!ticket.assets){
      ticket.assets = [];
    }

    var form = new Backbone.Form({
      schema: {
        resident_id: 'Hidden',
        status: {
          type: 'Select',
          options: App.vars.ticketStatuses
        },
        description: {
          type: 'TextArea',
          editorAttrs: {
            placeholder: 'Problem Description'
          },
          validators: [{type: 'required', message: 'Description is required'}]
        },
        category_id: {
          type: 'Select',
          options: App.vars.ticketCategories,
          validators: [{type: 'required', message: 'Category is required'}]
        },
        assignee_id: {
          type: 'Select',
          options: App.vars.ticketAssignees,
          validators: [{type: 'required', message: 'Assignee is required'}]
        },
        urgency: {
          type: 'Radio',
          options: App.vars.ticketUrgencies,
          editorAttrs: {
            class: 'list-unstyled'
          }
        },
        can_enter: {
          type: 'Radio',
          options: [{ val: "1", label: 'Yes' }, { val: "0", label: 'No' }],
          editorAttrs: {
            class: 'list-unstyled'
          }
        },
        entry_instruction: 'Text',
        additional_emails: 'Text',
        additional_phones: 'Text'
      },
      template: JST['backbone/templates/tickets/form'],
      data: ticket,
      templateData: ticket
    }).render();

    this.form = form; //for events

    if(this.isCreateNew){
      $(form.el).append('\
        <button type="submit" class="btn btn-success btn-lg">Add Ticket</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>');
    } else {
      $(form.el).append('\
        <button type="submit" class="btn btn-success btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive" style="display:none">Archive</a>');
    }

    this.$el.html(form.el);

    return this;
  }
});
