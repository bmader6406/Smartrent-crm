Crm.Views.Smartrent = Backbone.View.extend({
  template: JST["backbone/templates/residents/smartrent"],

  events: {
    "click .status-dd li a": "setStatus",
    "click #reset-password button:submit": "resetPassword",
    "click #change-password button:submit": "changePassword",
    "click .edit-amount": "editAmount",
    "click .update-amount": "updateAmount",
    "click .cancel-amount": "cancelAmount"
  },

  initialize: function() {
	  //this.listenTo(this.model, 'change', this.render);
	},

  render: function () {
    //console.log(this.model, "smartrentData");
    this.$el.html( JST["backbone/templates/residents/smartrent"](this.model) );
  	return this;
  },

  setStatus: function(ev){
    var self = this,
      link = $(ev.target),
      status = $.trim(link.text()).toLowerCase().replace(" ", "-"),
      statusDd = link.parents('.status-dd');

    statusDd.find('> span').text( link.text() );
    statusDd.attr('class', 'status-dd smartrent-' + status);

    //use link.attr('data-index') to get the status number
    capitializedStatus = status.charAt(0).toUpperCase() + status.slice(1)

    $.ajax({
      type: 'POST',
      url: self.model.set_status_path,
      data: {smartrent_status : capitializedStatus},
      success: function(data) {
        msgbox("Smartrent Status was successfully updated");
        $('.view-smartrent').click();
      },
      error: function(){
        msgbox("There was an error updating your status", "danger");
      }
     });
  },
  
  editAmount: function(ev){
    var editor = $(ev.target).parent().next();
    
    editor.show();
    editor.prev().hide();
  },
  
  updateAmount: function(ev){
    var self = this,
      editor = $(ev.target).closest('.amount-editor');
    
    $.ajax({
      type: 'POST',
      url: self.model.set_amount_path,
      data: {reward_id : editor.attr('data-id'), amount: editor.find(':input').val()},
      success: function(data) {
        msgbox("Smartrent Status was successfully updated");
        $('.view-smartrent').click();
      },
      error: function(){
        msgbox("There was an error updating your status", "danger");
      }
     });
     
  },
  
  cancelAmount: function(ev){
    var editor = $(ev.target).closest('.amount-editor');
    
    editor.hide();
    editor.prev().show();
  },

  resetPassword: function(ev) {
    var form = $('#reset-password');
    
    bootbox.confirm("Sure you want to reset the resident's password?", function(result) {
      if (result) {
        form.ajaxSubmit({
          dataType: 'json',
          beforeSubmit: function(){
            form.mask('Please wait...');
          },
          success: function(data){
            form.unmask();

            if(data.success){
              msgbox('The password reset information have been sent!');
            }else {
              msgbox('There was an error, please try again', 'danger');
            }
          }
        });
      }
    });
    
  },

  changePassword: function(ev) {
    var form = $('#change-password');

    bootbox.confirm("Sure you want to change the resident's password?", function(result) {
      if (result) {
        form.ajaxSubmit({
          dataType: 'json',
          beforeSubmit: function(){
            form.mask('Please wait...');
          },
          success: function(data){
            form.unmask();
            if(data.success){
              msgbox('The password was successfully updated!');
            }else {
              msgbox('There was an error, please try again', 'danger');
            }
          }
        });
      }
    });
  }

});
