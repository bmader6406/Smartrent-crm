Crm.Views.ReplyEmailForm = Backbone.View.extend({
  id: 'email-wrap',
  events:	{
		"submit form": "sendEmail",
		"click .cancel": "cancel",
		"click .show-quoted": "showQuoted",
		"click #cc-roommates": "ccRoommates"
	},

  activity: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Activity().toJSON();
  },

  cancel: function(){
    this.$el.slideUp();
    return false;
  },

  sendEmail: function (ev) {
    var form = this.$('form'),
      editor = this.$('.redactor_editor');

    editor.find('.show-quoted').remove();

    this.$('#message').val( editor.html() ); //refresh

    var self = this,
      params = {
        comment: {type: 'email'},
        email: self.$('form').toJSON()
      },
      errors = self.form.validate();

    if( !errors ) {

      form.mask('Please wait...');

      $.post(form.attr('action'), params, function(data){
        $.each(data, function(i, d){
          var activityView = new Crm.Views.Activity({ model: new Crm.Models.Activity(d) });

          if( i == 0 ) { //updated activity
            form.closest('.resident-box').parent().replaceWith(activityView.render().el);

          } else { //new reply
            $('#resident-history .activities').prepend(activityView.render().el)
          }
        });

        Crm.collInst.quickNotifications.fetch({reset: true});

      }, 'json').fail(function(){
        msgbox("There was an error while replying the email, please try again", "danger");

      }).always(function(){
        form.unmask();

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

  ccRoommates: function(ev){
    var self = this;
    $.getJSON(self.resident.attributes.roommates_path, function(data){
      if (data.length > 0) {
        var roommates = [],
          cc = self.$('[name="cc"]'),
          to = self.$('[name="to"]').val(),
          ccValue = cc.val().trim(),
          ccEmails = [],
          emails = ccValue.split(",");
          
        _.each(emails, function(e) {
          if (e.length > 0) {
            ccEmails.push(e.trim());
          }
        });
        
        _.each(data, function(r){
          if (!_.contains(ccEmails, r.email) && App.getEmailFromStr(r.email) != App.getEmailFromStr(to)) {
            ccEmails.push(r.full_name + " <" + r.email + ">");
          }
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
            editorAttrs: {readonly: true},
            validators: [
              function checkEmail(value, formValues) {
                var arr = App.getInvalidEmails(value);

                if(arr.length > 0) {
                  return {
                    type: 'required',
                    message: 'Sender email is not valid'
                  }
                }
              }
            ]
          },
          to: {
            validators: [
              function checkEmail(value, formValues) {
                var arr = App.getInvalidEmails(value);

                if(arr.length > 0) {
                  return {
                    type: 'required',
                    message: 'Recipient is required'
                  }
                }
              }
            ]
          },
          cc: {
            validators: [
              function checkEmail(value, formValues) {
                var arr = App.getInvalidEmails(value);

                if(arr.length > 0) {
                  return {
                    type: 'required',
                    message: arr.join(',') + ' in CC are invalid email addresses'
                  }
                }
              }
            ]
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
          from: App.vars.propertyObj.name + " <" + App.vars.propertyEmail + ">",
          to: resident.get("full_name") + " <" + resident.get("email") + ">"
        }
      }).render();

    this.form = form; //for events

    this.$el.html(form.el);

    return this;
  }
});
