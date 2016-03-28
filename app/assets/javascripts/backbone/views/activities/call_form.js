Crm.Views.CallForm = Backbone.View.extend({
  id: 'call-wrap',
  
  events:	{
		"submit form": "callResident",
		"click .cancel": "cancel"
	},
	
  activity: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Activity().toJSON();
  },
  
  cancel: function(){
    $('#toolbar .btn.selected').click();
    //$(this.form.el).resetForm();
    $(this.form.el).find("#message").val("");
    
    return false;
  },
  
  callResident: function (ev) {
    var self = this,
      method = this.collection.create,
      params = { 
        comment: {type: 'phone'},
        call: self.$('form').toJSON()
      },
      errors = self.form.validate();
    
    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Call was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          App.showMask();
          
          setTimeout(function(){
            msgbox(App.vars.twilioNumber + ' is calling. Please check your phone');
            $('.no-histories').hide();
            //$(self.form.el).resetForm();
            $(self.form.el).find("#message").val("");

            self.$el.slideUp();
            $('#toolbar .btn').removeClass('selected');
            
            App.hideMask();
          }, 5000);
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

  render: function () {
    var self = this,
      resident = this.resident,
      form = new Backbone.Form({
        schema: {
          from: { 
            validators: [{type: 'required', message: 'Your # is required'}]
          },
          to: { 
            validators: [{type: 'required', message: 'Resident # is required'}]
          },
          message: {
            type: 'TextArea',
            editorAttrs: {
              placeholder: 'Write your note here...'
            }
          }
        },
        template: JST['backbone/templates/activities/call_form'],
        data: {
          from: self.addPhoneCode(App.vars.propertyPhone),
          to: self.addPhoneCode(resident.get("primary_phone"))
        }
      }).render();

    this.form = form; //for events

    this.$el.html(form.el);
    
    //phone field
    this.$('#from').intlTelInput({
      responsiveDropdown: false,
      autoFormat: true,
      utilsScript: '/libphonenumber/utils.js'
    });

    this.$('#to').intlTelInput({
      responsiveDropdown: false,
      autoFormat: true,
      utilsScript: '/libphonenumber/utils.js'
    });

    return this;
  },
  
  addPhoneCode: function(number) {
    if(number && !number.indexOf("+1") > -1) {
      return "+1 " + number;
    }
    return number;
  }
});