Crm.Views.ResidentDetail = Backbone.View.extend({
  template: JST["backbone/templates/residents/detail"],
  id: 'resident-detail',
  
  events: {
    "click .new-call": "newCall",
    "click .new-email": "newEmail",
    "click .new-note": "newNote",
    "click .new-upload": "newUpload",
    "click .new-ticket": "newTicket",
    "click .new-roommate": "newRoommate",
    "click .view-all": "viewAll",
    "click .view-smartrent": "viewSmartrent",
	},
  
  initialize: function() {
	  //activities form
	  this.callForm = null;
	  this.emailForm = null;
	  this.noteForm = null;
	  this.uploadForm = null;
	  this.ticketForm = null;
	},
  
  render: function () {
  	var self = this,
  	  scrollEnd = false;
  	  
  	this.$el.html(this.template(this.model.toJSON()));
  	this.formWrap = this.$('#form-wrap');
  	this.residentHistory = this.$('#resident-history');
  	
  	//scroll to load more
  	setTimeout(function(){
    	self.$el.on('scroll', function() {
    	  if(self.residentHistory.is(":visible")){
    	    if($(this).scrollTop() + $(this).innerHeight() >= this.scrollHeight - 50) {
            scrollEnd = true;
          } else {
            scrollEnd = false;
          }

          if(scrollEnd && Crm.collInst.residentActivities.state.nextLink) {
            try{ Crm.collInst.residentActivities.getNextPage() } catch(ex) {}
            scrollEnd = false;
          }
    	  }
      });
  	}, 200);
        
  	return this;
  },
    
  newCall: function(ev){
    if( !this.callForm ) {
      this.callForm = new Crm.Views.CallForm({
        collection: Crm.collInst.residentActivities
      });
      this.callForm.resident = this.model;
      this.formWrap.append( this.callForm.render().el );
    }
    
    if( this.$('#call-wrap:visible')[0] ){
      this.$('#call-wrap').slideUp();
      this.$('#toolbar .btn').removeClass('selected');
      this.$('.activities .resident-box').fadeIn();
      
    } else {
      this.formWrap.find('> div').hide();
      this.$('#toolbar .btn').removeClass('selected').end().find('.new-call').addClass('selected');
      this.$('#call-wrap').slideDown();
      this.$('.activities .resident-box').hide();
      this.$('.activities .call-act').fadeIn();
    }
    
    $('#center').scrollTo('#toolbar', {duration: 400, offset: -20});
  },
  
  newEmail: function(ev){
    if( !this.emailForm ) {
      this.emailForm = new Crm.Views.EmailForm({
        collection: Crm.collInst.residentActivities
      });
      this.emailForm.resident = this.model;
      this.formWrap.append( this.emailForm.render().el );
      
      this.$('#email-wrap #message').redactor({
        focus: true, 
        convertDivs: false,
        convertLinks: false,
        cleanup: false,
        height: 250,
        buttons: [
          'html', '|', 'bold', 'italic', 'underline', 'deleted','|', 'fontcolor', 'backcolor', '|', 'link'
        ]
      });
    }
    
    if( this.$('#form-wrap #email-wrap:visible')[0] ){
      this.$('#form-wrap #email-wrap').slideUp();
      this.$('#toolbar .btn').removeClass('selected');
      this.$('.activities .resident-box').fadeIn();
      
    } else {
      this.formWrap.find('> div').hide();
      this.$('#toolbar .btn').removeClass('selected').end().find('.new-email').addClass('selected');
      this.$('#form-wrap #email-wrap').slideDown();
      this.$('.activities .resident-box').hide();
      this.$('.activities .email-act').fadeIn();
    }
    
    
    $('#center').scrollTo('#toolbar', {duration: 400, offset: -20});
  },
  
  newNote: function(ev){
    if( !this.noteForm ) {
      this.noteForm = new Crm.Views.NoteForm({
        collection: Crm.collInst.residentActivities
      });
      this.noteForm.resident = this.model;
      this.formWrap.append( this.noteForm.render().el );
      
    }
    
    if( this.$('#note-wrap:visible')[0] ){
      this.$('#note-wrap').slideUp();
      this.$('#toolbar .btn').removeClass('selected');
      this.$('.activities .resident-box').fadeIn();
      
    } else {
      this.formWrap.find('> div').hide();
      this.$('#toolbar .btn').removeClass('selected').end().find('.new-note').addClass('selected');
      this.$('#note-wrap').slideDown();
      this.$('.activities .resident-box').hide();
      this.$('.activities .note-act').fadeIn();
    }
    
    $('#center').scrollTo('#toolbar', {duration: 400, offset: -20});
  },
  
  newUpload: function(ev){
    if( !this.uploadForm ) {
      this.uploadForm = new Crm.Views.DocumentUploadForm({
        collection: Crm.collInst.residentActivities
      });
      this.uploadForm.resident = this.model;
      this.formWrap.append( this.uploadForm.render().el );
      
    }
    
    if( this.$('#upload-wrap:visible')[0] ){
      this.$('#upload-wrap').slideUp();
      this.$('#toolbar .btn').removeClass('selected');
      this.$('.activities .resident-box').fadeIn();
      
    } else {
      this.formWrap.find('> div').hide();
      this.$('#toolbar .btn').removeClass('selected').end().find('.new-upload').addClass('selected');
      this.$('#upload-wrap').slideDown();
      this.$('.activities .resident-box').hide();
      this.$('.activities .document-act').fadeIn();
    }
    
    $('#center').scrollTo('#toolbar', {duration: 400, offset: -20});
  },
  
  newTicket: function(ev){
    if( !this.ticketForm ) {
      Crm.collInst.residentTickets = new Crm.Collections.ResidentTickets;
      Crm.collInst.residentTickets.url = App.vars.routeRoot + "/tickets";
      
      this.ticketForm = new Crm.Views.TicketNew({
        collection: Crm.collInst.residentTickets
      });
      this.ticketForm.resident = this.model;

      this.formWrap.append( this.ticketForm.render().el );      
    }
    
    if( this.$('#ticket-wrap:visible')[0] ){
      this.$('#ticket-wrap').slideUp();
      this.$('#toolbar .btn').removeClass('selected');
      this.$('.activities .resident-box').fadeIn();
      
    } else {
      this.formWrap.find('> div').hide();
      this.$('#toolbar .btn').removeClass('selected').end().find('.new-ticket').addClass('selected');
      this.$('#ticket-wrap').slideDown();
      this.$('.activities .resident-box').hide();
      this.$('.activities .ticket-act').fadeIn();
    }
    
    $('#center').scrollTo('#toolbar', {duration: 400, offset: -20});
  },
  
  newRoommate: function(ev){
    if( !this.roommateForm ) {
      //switch to roommates resource
      Crm.collInst.residentRoommates.url = App.vars.routeRoot + "/roommates?unit_id=" + this.model.get('unit').unit_id;

      this.roommateForm = new Crm.Views.RoommateNew({
        collection: Crm.collInst.residentRoommates
      });
      this.roommateForm.resident = this.model; 
    }

    this.$('.roommates').before( this.roommateForm.render().el );
    $('#roommate-wrap').show();
  },
  
  viewAll: function(){
    this.formWrap.find('> div').hide();
    this.$('.activities .resident-box').show();
    this.$('#toolbar .btn').removeClass('selected').end().find('.view-all').addClass('selected');
    
    return false;
  },
  
  viewSmartrent: function(){
    $('#resident-info .nav-details a[href="#smartrent"]').click();
    return false;
  }
});
