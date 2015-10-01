Crm.Views.ReplyEmailForm = Backbone.View.extend({
  id: 'email-wrap',
  events:	{
		"submit form": "sendEmail",
		"click .cancel": "cancel",
		"click .show-quoted": "showQuoted"
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
              {type: 'email', message: 'CC email is not valid'}
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
          from: App.vars.propertyEmail,
          to: resident.get("email")
        }
      }).render();

    this.form = form; //for events

    this.$el.html(form.el);

    return this;
  }
});
