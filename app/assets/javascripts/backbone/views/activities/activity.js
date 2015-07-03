Crm.Views.Activity = Backbone.View.extend({
  tagName: 'li',

  events: {
    "click .delete": "_delete",
    "click .reply-email": "replyEmail",
    "click .show-quoted": "showQuoted"
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
  
  replyEmail: function (ev) {
    var self = this,
      residentBox = $(ev.target).parents('.resident-box');
    
    $('.new-email').click();
    
    setTimeout(function(){
      var emailWrap = $('#email-wrap');
      emailWrap.find('#subject').val($.trim( residentBox.find('.subject').text() ));
      emailWrap.find('#from').val(App.vars.propertyEmail);
      emailWrap.find('#to').val(self.model.get('email').from);
      emailWrap.find('.redactor_editor').html('<br><br> <div class="show-quoted" title="show trimmed content" style="display:none">...</div>' +
        '<blockquote class="hyly_quoted" style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex">'+ 
        $.trim( residentBox.find('.message').html() ) + '</blockquote>');
    }, 100);
    
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
