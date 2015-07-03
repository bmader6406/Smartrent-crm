Crm.Views.CampaignNewOrUpdate = Backbone.View.extend({
  
  events:	{
		"submit form": "createOrUpdate",
		"click .archive": "archive",
		"click .cancel": "hideForm",
		"keyup #body_text": "livePreview"
	},
  
  campaign: function(){
    return this.model !== undefined ? this.model.toJSON() : new Crm.Models.Campaign().toJSON();
  },
  
  createOrUpdate: function (ev) {
    var self = this,
      method = this.isCreateNew ? this.collection.create : this.model.save,
      params = { campaign: self.$('form').toJSON() },
      errors = self.form.validate();

    params.published_at = this.getScheduleTime();

    if( !errors ) {  
      method.call(this.model || this.collection, params, {
        wait: true,
        error: function (model, xhr) {
          var errors = $.parseJSON(xhr.responseText);
          msgbox('Notice was not saved! ' + errors.join(", "), 'danger');
        },
        success: function (model, response) {
          if(self.isCreateNew){
            msgbox('Notice was created successfully!');
            
          } else {
            msgbox('Notice was updated successfully!');
          }
          
          //must update the campaignObj with the lastest info
          if(App.vars.campaignObj){
            App.vars.campaignObj = response;
          }
          
          self.hideForm();
          Crm.routerInst.navigate('/notices', true);
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
  
  archive: function(evt){
	  var self = this;
	  
	  bootbox.confirm("Sure you want to archive this notice?", function(result) {
      if (result) {
        self.model.url = App.vars.campaignsUrl.replace(/\?.*/, '') + "/" + self.model.get('id');
        self.model.destroy({
          success: function(model, response) {
            msgbox("Notice was archived successfully");
            Crm.routerInst.navigate('/notices', true);
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
    var campaign = this.campaign();

    campaign.isCreateNew = this.isCreateNew;
    
    if(campaign.isCreateNew){
      campaign.from = App.vars.propertyEmail;
    }
    
    var schema = {},
      baseSchema = {
        subject: {
          validators: [{type: 'required', message: 'Subject is required'}]
        },
        from: {
          validators: [{type: 'required', message: 'From is required'}]
        },
        audience_id: { 
          type: 'Select',
          validators: [{type: 'required', message: 'To is required'}],
          options: App.vars.propertyAudiences
        },
        body_text: { 
          type: 'TextArea',
          validators: [{type: 'required', message: 'Body Text is required'}]
        }
      };
    
   var templateHtml = JST['backbone/templates/campaigns/form'](campaign);

    $(templateHtml).find('div[data-editors]').each(function(i, div){
      var field = $(div).attr('data-editors');
      schema[field] = baseSchema[field];
    });

    var form = new Backbone.Form({
      schema: schema,
      template: _.template(templateHtml),
      data: campaign
    }).render();
    
    form.$('#body_text').redactor({
      focus: true, 
      convertDivs: false,
      convertLinks: false,
      cleanup: false,
      height: 250,
      buttons: [
        'html', '|', 'bold', 'italic', 'underline', 'deleted','|', 'fontcolor', 'backcolor', '|', 'link'
      ],
      keyupCallback: function(editor, ev){
        setTimeout(function(){editor.$el.keyup();}, 30);
		  },
		  execCommandCallback: function(editor, ev){
        if(ev){ //close trigger ev undefined
          setTimeout(function(){editor.$el.keyup();}, 30);
        }
  		}
    });
    
    this.form = form; //for events

    
    if(this.isCreateNew){
      $(form.el).append('\
        <button type="submit" class="btn btn-primary btn-lg">Create Notice</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>').find('.collapse:first').addClass('in');
    } else {
      $(form.el).append('\
        <button type="submit" class="btn btn-primary btn-lg">Save</button>\
        <a href="#" class="btn btn-default btn-lg cancel">Cancel</a>\
        <a href="#" class="btn btn-default btn-lg archive">Archive</a>').find('.collapse:first').addClass('in');
    }

    this.$el.html(form.el);

    //schedule time
    this.setupScheduleTime();
    
    this.showForm();

    return this;
  },

  showForm: function(){
    $('#campaign-search').hide();
    $('#campaigns').hide();
    $('#campaign-preview').show();
    $('#campaign-editor').show().html(this.el);
    
    //insert preview iframe
    $('#live-iframe').remove();
    var url = App.vars.templatePreviewUrl;
    if(this.model){
      url += "?cid=" + this.model.get('id');
    }
    $('#center').addClass('previewing').append('<iframe frameborder="0" src="'+url+'" id="live-iframe"></iframe>');
    App.layout.sizePane('west', 455);
  },
  
  hideForm: function(){
    $('#campaign-editor, #live-iframe').hide();
    $('#campaigns').show();
    $('#campaign-search').show();
    $('#center').removeClass('previewing');
    App.layout.sizePane('west', 305);
    
    Crm.routerInst.navigate('/notices', true);
  },
  
  setupScheduleTime: function(){
    var scheduleDate = this.$("#schedule-date"),
      timeSelect = scheduleDate.closest('.time-select');
      hour = timeSelect.find("#hour"),
      minute = timeSelect.find("#minute"),
      meridiem = timeSelect.find("#meridiem"),
      tz = timeSelect.find('.tz');

    tz.replaceWith(App.vars.propertyTzHack);
    tz = timeSelect.find('.tz'); //renew el
    
    //manual set date time from default or DB
    if(this.model) {
      var date = this.model.get('published_date'),
        time = $.trim(this.model.get('published_time'));
        
    } else {
      var date = moment().add(1, 'day').format("YYYY-MMM-DD"),
        time = "11:00 PM"
    }
    
    scheduleDate.val(date);
    hour.val(time.split(":")[0]);
    minute.val(time.split(":")[1].split(" ")[0]);
    meridiem.val(time.split(":")[1].split(" ")[1]);
    
    function disablePastTime(dateText){
      var dh = parseInt(tz.attr("data-h")),
        dm = parseInt(tz.attr("data-m"));

      timeSelect.find('option').removeAttr("disabled");

      if(dateText == tz.attr("data-date")){ //disable the past time of today

        if(tz.attr("data-mer") == "PM"){
          meridiem.find('option:first').attr("disabled", "disabled");
          meridiem.val("PM");

          hour.find('option').each(function(){
            var opt = $(this);

            if( parseInt(opt.val()) < dh && dh != 12 ){
              opt.attr("disabled", "disabled");
            }
          });

          hour.unbind('change').change(function(){
            if(hour.val() == dh){
              minute.find('option').each(function(){
                var opt = $(this);

                if( parseInt(opt.val()) < dm ){
                  opt.attr("disabled", "disabled");
                }
              });

              minute.val( minute.find("option:not(:disabled):first").val() );

            }else {
              minute.find('option').removeAttr('disabled');
            }
          });

        }else { // AM
          meridiem.find('option').removeAttr('disabled');

          hour.find('option').each(function(){
            var opt = $(this);

            if( parseInt(opt.val()) < dh  && dh != 12 && meridiem.val() == "AM" ){
              opt.attr("disabled", "disabled");
            }
          });

          hour.unbind('change').change(function(){
            if(hour.val() == dh && meridiem.val() == "AM" ){
              minute.find('option').each(function(){
                var opt = $(this);

                if( parseInt(opt.val()) < dm ){
                  opt.attr("disabled", "disabled");
                }
              });

              minute.val( minute.find("option:not(:disabled):first").val() );
            }else {
              minute.find('option').removeAttr('disabled');
            }
          });
        }

        if(hour.val() == null) hour.val( hour.find("option:not(:disabled):first").val() ).change();
      }
    }

    meridiem.change(function(){
      disablePastTime(scheduleDate.val());
    });

    scheduleDate.datepicker({
      format: 'yyyy-M-dd',
      startDate: new Date()
    }).on('changeDate', function(ev){
      disablePastTime(moment(ev.date).format("YYYY-MMM-DD"));
    });
  },
  
  getScheduleTime :function (){
    var timeSelect = this.$('.time-select'),
      time = [timeSelect.find('#schedule-date').val()]

    time.push(timeSelect.find("select[name=hour]").val()+":"+timeSelect.find("select[name=minute]").val()+
      " "+timeSelect.find("select[name=meridiem]").val());

    time.push(timeSelect.find(".tz").attr("data-z"));

    return time.join(" ");
  },
  
  livePreview: function(ev){
    var text = $(ev.target).val();
    
    if(!this.bodyTextDiv){
      this.bodyTextDiv = $('#live-iframe').contents().find('#hyly-body-text');
    }
    
    try{ this.bodyTextDiv.html(text) } catch(ex){};
  }
});