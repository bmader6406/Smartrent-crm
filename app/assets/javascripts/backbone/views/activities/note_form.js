Crm.Views.NoteForm = Backbone.View.extend({
  id: 'note-wrap',
  events:	{
		"submit form": "createNote",
		"click .cancel": "cancel"
	},
	
  activity: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Activity().toJSON();
  },
  
  cancel: function(){
    $('#toolbar .btn.selected').click();
    $(this.form.el).resetForm();
    
    return false;
  },
  
  createNote: function (ev) {
    var self = this,
      method = this.collection.create,
      params = { comment: self.$('form').toJSON() },
      errors = self.form.validate();
      
    params.comment.type = 'note';

    if( !errors ) {
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Note was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          msgbox('Note was created successfully!');
          $('.no-histories').hide();
          $(self.form.el).resetForm();
          
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

  render: function () {
    var resident = this.resident,
      form = new Backbone.Form({
        schema: {
          message: { 
            type: 'TextArea',
            editorAttrs: {
              placeholder: 'Write your note here...'
            },
            validators: [{type: 'required', message: 'Note is required'}]
          }
        },
        template: JST['backbone/templates/activities/note_form'],
        data: resident
      }).render();

    this.form = form; //for events

    this.$el.html(form.el);

    return this;
  }
});