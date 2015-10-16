Crm.Views.Activity = Backbone.View.extend({
  tagName: 'li',

  events: {
    "click .delete": "_delete",
    "click .acknowledge": "acknowledge",
    "click .show-reply-form": "showReplyForm",
    "click .show-headers": "showHeaders",
    "click .change-recipient": "changeRecipient",
    "click .show-share-form": "showShareForm",
    "click .show-logs": "showLogs",
    "click .hide-logs": "hideLogs",
    "click .show-quoted": "showQuoted",
    "click .edit-note": "editNote",
    "click .cancel-note": "cancelNote",
    "click .update-note": "updateNote",
  },
  
  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
	
  render: function () {
    var activity = this.model.toJSON(),
      template = null;

    if(activity.marketing) {
      template = JST["backbone/templates/activities/marketing"];
      
    } else if(activity.note) {
      template = JST["backbone/templates/activities/note"];
    
    } else if(activity.email) {
      template = JST["backbone/templates/activities/email"];
      
    } else if(activity.call) {
      template = JST["backbone/templates/activities/call"];
      
    } else if(activity.document) {
      template = JST["backbone/templates/activities/document"];
      
    } else if(activity.ticket) {
      template = JST["backbone/templates/activities/ticket"];
    }
    
    if(template) this.$el.html( template(activity) );
    
    if(activity.email) {
      //add [...] if .gmail_extra, .yahoo_quoted, outlook (.MsoNormal)
      var extra = this.$('.gmail_extra, .yahoo_quoted, .hyly_quoted');
      
      if(extra[0]){
        extra.before('<div class="show-quoted" title="show trimmed content" style="display:none">...</div>');
      } else {
        
      }
    }
    
  	return this;
  },
  
  showQuoted: function(ev){
    this.$('.show-quoted').each(function(){
      $(this).attr('style', 'display:none !important;').next().show();
    });
    return false;
  },
  
  acknowledge: function(ev){
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    residentBox.mask('Loading...');

    $.post(this.model.get('notification').acknowledge_path, function(data){
      var activityView = new Crm.Views.Activity({ model: new Crm.Models.Activity(data) });
      residentBox.parent().replaceWith(activityView.render().el);
      
      Crm.collInst.quickNotifications.fetch({reset: true});
      
    }, 'json').fail(function(){
      msgbox("There was an error while updating the activity, please try again", "danger");
      
    }).always(function(){
      residentBox.unmask();

    });
      
    return false;
  },
  
  showReplyForm: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    if( !this.replyEmailForm ) {
      this.replyEmailForm = new Crm.Views.ReplyEmailForm();
      this.replyEmailForm.resident = Crm.collInst.residentActivities.resident;
      
      residentBox.append( this.replyEmailForm.render().el );
      residentBox.find('form').attr('action', this.model.get('notification').reply_path);
      
      var emailWrap = residentBox.find('#email-wrap'),
        resident = Crm.collInst.residentActivities.resident;
        
      emailWrap.find('#message').redactor({
        focus: true, 
        convertDivs: false,
        convertLinks: false,
        cleanup: false,
        height: 250,
        buttons: [
          'html', '|', 'bold', 'italic', 'underline', 'deleted','|', 'fontcolor', 'backcolor', '|', 'link'
        ]
      });
      
      //setTimeout(function(){
        emailWrap.find('#subject').val($.trim( residentBox.find('.subject').text() ));
        emailWrap.find('#from').val(App.vars.propertyObj.name + " <" + App.vars.propertyEmail + ">");
        emailWrap.find('#to').val(self.model.get('email').from);
        
        //show warning message
        if(self.model.get('email').from.indexOf(resident.email) == -1 ){
          var msg = "You are responding to " + self.model.get('email').from +
            " . <a href='#' class='alert-link change-recipient'>Click here</a>" +
            " to change the recipient to <b>" + resident.get('full_name') + " &lt;" + resident.get('email') + "&gt; </b>";
          
          emailWrap.find('#to').after("<div class='alert alert-warning'>" + msg + "</div>");
        }
        
        emailWrap.find('#cc').val(self.model.get('email').cc);
        emailWrap.find('.redactor_editor').html('<br><br> <div class="show-quoted" title="show trimmed content" style="display:none">...</div>' +
          '<blockquote class="hyly_quoted" style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex">'+ 
          $.trim( residentBox.find('.message').html() ) + '</blockquote>');
      //}, 100);
    
    } else {
      residentBox.find('#email-wrap').slideDown();
    }
    
    return false;
  },
  
  showHeaders: function(ev) {
    this.$('.headers').toggle();
    return false;
  },
  
  changeRecipient: function(){
    var resident = Crm.collInst.residentActivities.resident;
    this.$("#to").val(resident.get('full_name') + " <" + resident.get('email') + ">");
    this.$('#cc-roommates').click();
    this.$('.alert').slideUp();
  },
  
  showShareForm: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');

    if( !this.shareForm ) {
      this.shareForm = new Crm.Views.ShareForm();
      this.shareForm.resident = Crm.collInst.residentActivities.resident;
      
      residentBox.append( this.shareForm.render().el );
      
      var emailWrap = residentBox.find('#email-wrap'),
        resident = Crm.collInst.residentActivities.resident;
        
      residentBox.find('form').attr('action', resident.get('activities_path'));

      emailWrap.find('#message').redactor({
        focus: true, 
        convertDivs: false,
        convertLinks: false,
        cleanup: false,
        height: 250,
        buttons: [
          'html', '|', 'bold', 'italic', 'underline', 'deleted','|', 'fontcolor', 'backcolor', '|', 'link'
        ]
      });

      var shareHtml = "<br><br>---<br>Attached documents:";
      
      $.each(self.model.get('document').assets, function(i, a){
        shareHtml += "<br> - <a href='"+a.url+"' target='_blank'> "+ a.name +"</a>";
      });
      
      emailWrap.find('.redactor_editor').html(shareHtml);

    } else {
      residentBox.find('#email-wrap').slideDown();
    }

    return false;
  },
  
  showLogs: function(ev){
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    residentBox.find('.show-logs').hide();
    residentBox.find('.histories > div').fadeIn();
      
    return false;
  },
  
  hideLogs: function(ev){
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    residentBox.find('.histories > div').hide();
    residentBox.find('.show-logs').show();
    
    return false;
  },
  
  editNote: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    residentBox.find('.note-form').slideDown();
    residentBox.find('.note-form textarea').focus();
    
    return false;
  },
  
  cancelNote: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    residentBox.find('.note-form').slideUp();
    
    return false;
  },
  
  updateNote: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box'),
      form = residentBox.find('.note-form');
    
    form.ajaxSubmit({
      method: "POST",
      dataType: 'json',
      beforeSubmit: function(){
        form.mask('Please wait...');
      },
      success: function(data){
        form.unmask();
        
        if(residentBox.hasClass('call-act')) {
          residentBox.find('.message span').html("Note: " + form.find('textarea').val());
        } else {
          residentBox.find('.message span').html( form.find('textarea').val() );
        }
        
        if(data.success){
          msgbox('Note was successfully updated!');
        }else {
          msgbox('There was an error, please try again', 'danger');
        }
      }
    });
    
    residentBox.find('.note-form').slideUp();
    
    return false;
  },
  
  _delete: function (evt) {
    var self = this;

    bootbox.confirm("Sure you want to delete this activity? There is no undo", function(result) {
      if (result) {
        self.model.url = Crm.collInst.residentActivities.url.replace(/\?.*/, '') + "/" + self.model.get('id');
        self.model.destroy({
          success: function(model, response) {
            msgbox("Activity was archived successfully");
            self.remove();
          },
          error: function(model, response) {
            msgbox("There was an error, please try again.", "danger");
          }
        });
        self.model.url = null; //use collection url
      }
    });
    
    evt.stopPropagation();

    return false;
  }
  
});
