Crm.Views.EmailForm = Backbone.View.extend({
  id: 'email-wrap',
  events:	{
		"submit form": "sendEmail",
		"click .cancel": "cancel",
		"click .show-quoted": "showQuoted",
		"click #add-roommates": "addRoomMates"
	},

  activity: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Activity().toJSON();
  },

  cancel: function(){
    $('#toolbar .btn.selected').click();
    //$(this.form.el).resetForm();
    $(this.form.el).find("#subject, #message").val("");
    this.$('.redactor_editor').empty();

    return false;
  },

  sendEmail: function (ev) {
    var editor = this.$('.redactor_editor');
    editor.find('.show-quoted').remove();
    this.$('#message').val( editor.html() ); //refresh

    var self = this,
      method = this.collection.create,
      params = {
        comment: {type: 'email'},
        email: self.$('form').toJSON()
      },
      errors = self.form.validate();

    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText)
          msgbox('Activity was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          msgbox('Activity was created successfully!');
          $('.no-histories').hide();
          //$(self.form.el).resetForm();
          $(self.form.el).find("#subject, #message").val("");
          self.$('.redactor_editor').empty();

          self.$el.slideUp();
          $('#toolbar .btn').removeClass('selected');
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

  showQuoted: function(ev){
    this.$('.show-quoted').each(function(){
      $(this).attr('style', 'display:none !important;').next().show();
    });
    return false;
  },
  addRoomMates: function(ev){
    var self = this;
    $.getJSON(self.resident.attributes.roommates_path, function(data){
      if (data.length > 0) {
      var roommates = [],
        cc = self.$('[name="cc"]'),
        to = self.$('[name="to"]').val(),
        ccValue = cc.val().trim(),
        ccEmails = [],
        emails = ccValue.split(",");
        _.each(emails, function(email) {
          if (email.length > 0)
            ccEmails.push(email.trim());
        });
        _.each(data, function(value){
          if (!_.contains(ccEmails, value.email) && value.email != to)
            ccEmails.push(value.email);
        });
        cc.val(ccEmails.join(", "));
      }
    });
    return false;
  },

  render: function () {
    var resident = this.resident,
      form = new Backbone.Form({
        schema: {
          from: {
            validators: [
              {type: 'required', message: 'Sender is required'},
              {type: 'email', message: 'Sender email is not valid'}
            ]
          },
          to: {
            validators: [
              {type: 'required', message: 'Recipient is required'},
              {type: 'email', message: 'Recipient email is not valid'}
            ]
          },
          cc: {
            validators: [
              function checkEmail(value, formValues) {
                  var err = {
                      type: 'cc',
                      message: ''
                  };
                  var emails = value.split(",")
                  var invalidEmails = []
                  if (emails.length > 0) {
                    _.each(emails, function(email){
                      if (email.length > 0 && !App.validateEmail(email.trim()))
                        invalidEmails.push(email.trim())
                    });
                  }
                  if (invalidEmails.length > 0) {
                    err.message = invalidEmails.join(',') + ' in cc are invalid email addresses'
                    return err;
                  }
              }]
          },
          subject: {
            validators: [{type: 'required', message: 'Subject is required'}]
          },
          message: {
            type: 'TextArea',
            validators: [{type: 'required', message: 'Message is required'}]
          },
        },
        template: JST['backbone/templates/activities/email_form'],
        data: {
          from: App.vars.propertyEmail,
          to: resident.get("email")
        }
      }).render();

    this.form = form; //for events

    this.$el.html(form.el);

    return this;
  }
});
