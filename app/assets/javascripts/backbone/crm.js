window.Crm = {
  Models: {},
  Collections: {},
  Views: {},
  viewInst: {},
  collInst: {},
  initialize: function() {
    //app router
    var router = new Crm.Router(),
      self = this;
    
    this.leftMenu = $('#left-menu');
    
    $(document).on("click", "a[href^='/crm']", function(event){
      var href = $(event.currentTarget).attr('href'),
        target = $(event.currentTarget).attr('target'),
        sameProp = href.indexOf(App.vars.routeRoot) > -1,
        passThrough = href.indexOf('sign_out') > -1 || target // chain 'or's for other black list routes

      // Allow shift+click for new tabs, etc.
      if (sameProp && !passThrough && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey){
        // Remove leading slashes and hash bangs (backward compatablility)
        var url = href.replace(/crm\/\d+\//, '').replace(/^\//,'').replace('\#\!\/','');

        // Instruct Backbone to trigger routing events
        router.navigate(url, true);
        
        return false
      }
    });
    
    //residents
    Crm.collInst.residents = new Crm.Collections.Residents();

    router.on('route:showResidents', function() {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var residentSearch = new Crm.Views.ResidentSearch(),
        residentsList = new Crm.Views.ResidentsList({
          collection: Crm.collInst.residents
        });

      $('#west').html(residentSearch.render().$el);
      $('#center').html(residentsList.render().$el);
      
      
      self.highlightNav("residents");
      App.layout.show('west');
    });

    router.on('route:showResident', function(id) {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var resident = Crm.collInst.residents.get(id);

      if(!resident && App.vars.residentObj){
        resident = new Crm.Models.Resident( App.vars.residentObj );
        //manual set url if model not found in collection
        resident.url = Crm.collInst.residents.url + '/' + resident.get('id');
      }

      if(resident){
        var residentInfo = new Crm.Views.ResidentInfo({
          model: resident
        });

        var residentDetail = new Crm.Views.ResidentDetail({
          model: resident
        });
        
        $('#west').html(residentInfo.render().$el);
        $('#center').html(residentDetail.render().$el);
        
        //hack: highlight when needed only
        $('#resident-info .nav-details a:first').click();
        
        if( window.location.hash == "#addTicket"){
          setTimeout(function(){ //wait for activity to load
            residentDetail.$('.new-ticket').click();
          }, 1200);
        }
            
      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });
    
    router.on('route:showResidentTickets', function(id, tid) {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var resident = Crm.collInst.residents.get(id);

      if(!resident && App.vars.residentObj){
        resident = new Crm.Models.Resident( App.vars.residentObj );
        //manual set url if model not found in collection
        resident.url = Crm.collInst.residents.url + '/' + resident.get('id');
      }

      if(resident){
        var residentInfo = new Crm.Views.ResidentInfo({
          model: resident
        });

        Crm.collInst.residentTickets = new Crm.Collections.ResidentTickets;
        Crm.collInst.residentTickets.url = resident.get('tickets_path');

        var residentTicketsList = new Crm.Views.ResidentTicketsList({
          model: resident,
          collection: Crm.collInst.residentTickets
        });

        $('#west').html(residentInfo.render().$el);
        $('#center').html(residentTicketsList.render().$el);
        
        $('#resident-info .nav-details').find('a').removeClass('btn-primary').addClass('btn-default')
          .end().find('.ticket-nav').removeClass('btn-default').addClass('btn-primary');
        
          
        // show ticket detail or new ticket
        var hash = window.location.hash;
        if(hash.match(/#\d+/g)){
          setTimeout(function(){
            var editLink = $('.edit-ticket[data-id='+ hash.replace("#", "") +']:visible'),
              container = editLink.parents('.resident-box').parent();
              
            editLink.click();
            
            //hightlight
      			container.animate({ backgroundColor: "#FFFDDD" }, 500, function(){ 
      				$(this).animate({ backgroundColor: 'transparent' }, 1000);
      			});
        		
            $('#center').scrollTo(editLink, {duration: 400, offset: -20});
            
          }, 1200);
        }
        
      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });
    
    router.on('route:showResidentRoommates', function(id, tid) {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }

      var resident = Crm.collInst.residents.get(id);

      if(!resident && App.vars.residentObj){
        resident = new Crm.Models.Resident( App.vars.residentObj );
        //manual set url if model not found in collection
        resident.url = Crm.collInst.residents.url + '/' + resident.get('id');
      }

      if(resident){
        var residentInfo = new Crm.Views.ResidentInfo({
          model: resident
        });

        Crm.collInst.residentRoommates = new Crm.Collections.ResidentRoommates;
        Crm.collInst.residentRoommates.url = resident.get('roommates_path');

        var residentRoommatesList = new Crm.Views.ResidentRoommatesList({
          model: resident,
          collection: Crm.collInst.residentRoommates
        });

        $('#west').html(residentInfo.render().$el);
        $('#center').html(residentRoommatesList.render().$el);
          
        // show roommate detail or new roommate
        var hash = window.location.hash;
        if(hash.match(/#\d+/g)){
          setTimeout(function(){
            var editLink = $('.edit-roommate[data-id='+ hash.replace("#", "") +']:visible'),
              container = editLink.parents('.resident-box').parent();

            editLink.click();

            //hightlight
          	container.animate({ backgroundColor: "#FFFDDD" }, 500, function(){ 
          		$(this).animate({ backgroundColor: 'transparent' }, 1000);
          	});

            $('#center').scrollTo(editLink, {duration: 400, offset: -20});

          }, 1200);
        }

      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });
    
    router.on('route:showResidentProperties', function(id, tid) {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var resident = Crm.collInst.residents.get(id);

      if(!resident && App.vars.residentObj){
        resident = new Crm.Models.Resident( App.vars.residentObj );
        //manual set url if model not found in collection
        resident.url = Crm.collInst.residents.url + '/' + resident.get('id');
      }

      if(resident){
        var residentInfo = new Crm.Views.ResidentInfo({
          model: resident
        });

        residentProperties = new Crm.Collections.ResidentProperties;
        residentProperties.url = resident.get('properties_path');

        var residentPropertiesList = new Crm.Views.ResidentPropertiesList({
          model: resident,
          collection: residentProperties
        });

        $('#west').html(residentInfo.render().$el);
        $('#center').html(residentPropertiesList.render().$el);

      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });

    router.on('route:newResident', function() {
      if(!App.vars.ability.can("cud", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var residentSearch = new Crm.Views.ResidentSearch(),
        residentsList = new Crm.Views.ResidentsList({
          collection: Crm.collInst.residents
        });

      $('#west').html(residentSearch.render().$el);
      $('#center').html(residentsList.render().$el);
      
      new Crm.Views.ResidentNew({
        collection: Crm.collInst.residents
      }).render();

      self.highlightNav("residents");
    });

    router.on('route:editResident', function(id) {
      if(!App.vars.ability.can("cud", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var resident = Crm.collInst.residents.get(id);

      if(!resident && App.vars.residentObj){
        resident = new Crm.Models.Resident( App.vars.residentObj );
        //manual set url if model not found in collection
        resident.url = Crm.collInst.residents.url + '/' + resident.get('id');
      }
      
      var editResidentForm = new Crm.Views.ResidentEdit({
        model: resident
      });

      $('#center').html(editResidentForm.render().$el);
      
      App.layout.hide('west');
      self.highlightNav("residents");
    });
    
    //properties
    Crm.collInst.properties = new Crm.Collections.Properties();
    
    router.on('route:showProperties', function() {
      if(!App.vars.ability.can("read", "Property")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var propertySearch = new Crm.Views.PropertySearch(),
        propertiesList = new Crm.Views.PropertiesList({
          collection: Crm.collInst.properties
        });
        
      $('#west').html(propertySearch.render().$el);
      $('#center').html(propertiesList.render().$el);
      
      self.highlightNav("properties");
      App.layout.show('west');
    });
    
    router.on('route:showProperty', function(id) {
      if(!App.vars.ability.can("read", "Property")){
        Crm.unauthorizedAlert();
        return false;
      }

      var property = Crm.collInst.properties.get(id);
      
      if(!property && App.vars.propertyObj){
        property = new Crm.Models.Property( App.vars.propertyObj );
        //manual set url if model not found in collection
        property.url = Crm.collInst.properties.url + '/' + property.get('id');
      }
      
      if(property){
        var propertyInfo = new Crm.Views.PropertyInfo({
          model: property
        });

        var propertyDetail = new Crm.Views.PropertyDetail({
          model: property
        });

        $('#west').html(propertyInfo.render().$el);
        $('#center').html(propertyDetail.render().$el);
        
      } else {
        window.location.reload();
      }

      self.highlightNav("property-info");
      App.layout.show('west');
      //must below highlightNav
      var propInfoLink = self.leftMenu.find('li.admin-prop-info').show().find('a');
      if(property) propInfoLink.attr('href', property.get('info_path'));
    });

    router.on('route:newProperty', function() {
      if(!App.vars.ability.can("cud", "Property")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var propertySearch = new Crm.Views.PropertySearch(),
        propertiesList = new Crm.Views.PropertiesList({
          collection: Crm.collInst.properties
        });

      $('#west').html(propertySearch.render().$el);
      $('#center').html(propertiesList.render().$el);

      new Crm.Views.PropertyNew({
        collection: Crm.collInst.properties
      }).render();

      self.highlightNav("properties");
    });

    router.on('route:editProperty', function(id) {
      if(!App.vars.ability.can("cud", "Property")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var property = Crm.collInst.properties.get(id),
          editPropertyForm;
      
      if(!property && App.vars.propertyObj){
        property = new Crm.Models.Property( App.vars.propertyObj );
        //manual set url if model not found in collection
        property.url = Crm.collInst.properties.url + '/' + property.get('id');
      }
      if (property) {
        editPropertyForm = new Crm.Views.PropertyEdit({
          model: property
        });

        $('#center').html(editPropertyForm.render().$el);
      } else {
        window.location.reload();
      }
      
      App.layout.hide('west');
      self.highlightNav("property-info");
      self.leftMenu.find('li.admin-prop-info').show();
    });
    
    //tickets
    Crm.collInst.tickets = new Crm.Collections.Tickets();

    router.on('route:showTickets', function() {
      if(!App.vars.ability.can("read", "Ticket")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var ticketSearch = new Crm.Views.TicketSearch(),
        ticketsList = new Crm.Views.TicketsList({
          collection: Crm.collInst.tickets
        });

      $('#west').html(ticketSearch.render().$el);
      $('#center').html(ticketsList.render().$el);
        
      self.highlightNav("tickets");
      App.layout.show('west');
    });

    router.on('route:showTicket', function(id) {
      if(!App.vars.ability.can("read", "Ticket")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var ticket = Crm.collInst.tickets.get(id);

      if(!ticket && App.vars.ticketObj){
        ticket = new Crm.Models.Ticket( App.vars.ticketObj );
        //manual set url if model not found in collection
        ticket.url = Crm.collInst.tickets.url + '/' + ticket.get('id');
      }

      if(ticket){
        var ticketView = new Crm.Views.Ticket({
          model: ticket
        });


        $('#west').html('');
        $('#center').html(ticketView.render().$el);

      } else {
        window.location.reload();
      }

      self.highlightNav("tickets");
      App.layout.show('west');
    });

    router.on('route:newTicket', function() {
      if(!App.vars.ability.can("cud", "Ticket")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var ticketSearch = new Crm.Views.TicketSearch(),
        ticketsList = new Crm.Views.TicketsList({
          collection: Crm.collInst.tickets
        });

      $('#west').html(ticketSearch.render().$el);
      $('#center').html(ticketsList.render().$el);

      //show resident id/email dialog
      $('#tickets .add-new').click();

      self.highlightNav("tickets");
    });

    router.on('route:editTicket', function(id) {
      if(!App.vars.ability.can("cud", "Ticket")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var ticket = Crm.collInst.tickets.get(id),
          editTicketForm;
      
      if(!ticket && App.vars.ticketObj){
        ticket = new Crm.Models.Ticket( App.vars.ticketObj );
        //manual set url if model not found in collection
        ticket.url = Crm.collInst.tickets.url + '/' + ticket.get('id');
      }
      
      if (ticket) {
        editTicketForm = new Crm.Views.TicketEdit({
          model: ticket
        });

        $('#center').html(editTicketForm.render().$el);
      } else {
        router.navigate('tickets', true);
      }

      App.layout.hide('west');
      self.highlightNav("tickets");
    });
    
    ////roommates (CRUD)
    Crm.collInst.roommates = new Crm.Collections.Roommates();
    
    //units
    Crm.collInst.units = new Crm.Collections.Units();

    router.on('route:showUnits', function() {
      if(!App.vars.ability.can("read", "Unit")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var unitSearch = new Crm.Views.UnitSearch(),
        unitsList = new Crm.Views.UnitsList({
          collection: Crm.collInst.units
        });

      $('#west').html(unitSearch.render().$el);
      $('#center').html(unitsList.render().$el);

      self.highlightNav("units");
      App.layout.show('west');
    });

    router.on('route:showUnit', function(id) {
      if(!App.vars.ability.can("read", "Unit")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var unit = Crm.collInst.units.get(id);

      if(!unit && App.vars.unitObj){
        unit = new Crm.Models.Unit( App.vars.unitObj );
        //manual set url if model not found in collection
        unit.url = Crm.collInst.units.url + '/' + unit.get('id');
      }

      if(unit){
        var unitInfo = new Crm.Views.UnitInfo({
          model: unit
        });

        var unitDetail = new Crm.Views.UnitDetail({
          model: unit
        });

        $('#west').html(unitInfo.render().$el);
        $('#center').html(unitDetail.render().$el);

      } else {
        router.navigate('units', true);
      }

      self.highlightNav("units");
      App.layout.show('west');
    });

    router.on('route:newUnit', function() {
      if(!App.vars.ability.can("cud", "Unit")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var unitSearch = new Crm.Views.UnitSearch(),
        unitsList = new Crm.Views.UnitsList({
          collection: Crm.collInst.units
        });

      $('#west').html(unitSearch.render().$el);
      $('#center').html(unitsList.render().$el);

      new Crm.Views.UnitNew({
        collection: Crm.collInst.units
      }).render();

      self.highlightNav("units");
    });

    router.on('route:editUnit', function(id) {
      if(!App.vars.ability.can("cud", "Unit")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var unit = Crm.collInst.units.get(id),
          editUnitForm;
      
      if(!unit && App.vars.unitObj){
        unit = new Crm.Models.Unit( App.vars.unitObj );
        //manual set url if model not found in collection
        unit.url = Crm.collInst.units.url + '/' + unit.get('id');
      }
      
      if (unit) {
        editUnitForm = new Crm.Views.UnitEdit({
          model: unit
        });
        
        $('#center').html(editUnitForm.render().$el);
      } else {
        router.navigate('units', true);
      }
      
      App.layout.hide('west');
      self.highlightNav("units");
    });
    
    //campaigns
    Crm.collInst.campaigns = new Crm.Collections.Campaigns();

    router.on('route:showCampaigns', function() {
      if(!App.vars.ability.can("read", "Campaign")){
        Crm.unauthorizedAlert();
        return false;
      }

      var campaignSearch = new Crm.Views.CampaignSearch(),
        campaignsList = new Crm.Views.CampaignsList({
          collection: Crm.collInst.campaigns
        });

      $('#west').html(campaignSearch.render().$el);
      $('#center').html(campaignsList.render().$el);

      self.highlightNav("notices");
      App.layout.show('west');
    });

    router.on('route:showCampaign', function(id) {
      if(!App.vars.ability.can("read", "Campaign")){
        Crm.unauthorizedAlert();
        return false;
      }

      var campaign = Crm.collInst.campaigns.get(id);

      if(!campaign && App.vars.campaignObj){
        campaign = new Crm.Models.Campaign( App.vars.campaignObj );
        //manual set url if model not found in collection
        campaign.url = Crm.collInst.campaigns.url + '/' + campaign.get('id');
      }

      if(campaign){
        var campaignInfo = new Crm.Views.CampaignInfo({
          model: campaign
        });

        var campaignDetail = new Crm.Views.CampaignDetail({
          model: campaign
        });

        $('#west').html(campaignInfo.render().$el);
        $('#center').html(campaignDetail.render().$el);

      } else {
        router.navigate('notices', true);
      }

      self.highlightNav("notices");
      App.layout.show('west');
    });

    router.on('route:newCampaign', function() {
      if(!App.vars.ability.can("cud", "Campaign")){
        Crm.unauthorizedAlert();
        return false;
      }

      var campaignSearch = new Crm.Views.CampaignSearch(),
        campaignsList = new Crm.Views.CampaignsList({
          collection: Crm.collInst.campaigns
        });

      $('#west').html(campaignSearch.render().$el);
      $('#center').html(campaignsList.render().$el);

      new Crm.Views.CampaignNew({
        collection: Crm.collInst.campaigns
      }).render();

      self.highlightNav("notices");
    });

    router.on('route:editCampaign', function(id) {
      if(!App.vars.ability.can("cud", "Campaign")){
        Crm.unauthorizedAlert();
        return false;
      }

      var campaign = Crm.collInst.campaigns.get(id),
          editCampaignForm;

      if(!campaign && App.vars.campaignObj){
        campaign = new Crm.Models.Campaign( App.vars.campaignObj );
      }
      
      //manual set url
      campaign.url = Crm.collInst.campaigns.url + '/' + campaign.get('id');

      var campaignSearch = new Crm.Views.CampaignSearch(),
        campaignsList = new Crm.Views.CampaignsList({
          collection: Crm.collInst.campaigns
        });

      $('#west').html(campaignSearch.render().$el);
      $('#center').html(campaignsList.render().$el);
      
      if (campaign) {
        new Crm.Views.CampaignEdit({
          model: campaign,
          collection: Crm.collInst.campaigns
        }).render();
      } else {                             
        router.navigate('notices', true);  
      }

      self.highlightNav("notices");
    });
    
    //notifications
    Crm.collInst.notifications = new Crm.Collections.Notifications();

    router.on('route:showNotifications', function() {
      if(!App.vars.ability.can("read", "Notification")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var notificationSearch = new Crm.Views.NotificationSearch(),
        notificationsList = new Crm.Views.NotificationsList({
          collection: Crm.collInst.notifications
        });

      $('#west').html(notificationSearch.render().$el);
      $('#center').html(notificationsList.render().$el);

      self.highlightNav("notifications");
      App.layout.show('west');
    });

    router.on('route:showNotification', function(id) {
      if(!App.vars.ability.can("read", "Notification")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var notification = Crm.collInst.notifications.get(id);

      if(!notification && App.vars.notificationObj){
        notification = new Crm.Models.Notification( App.vars.notificationObj );
        //manual set url if model not found in collection
        notification.url = Crm.collInst.notifications.url + '/' + notification.get('id');
      }

      if(notification){
        var notificationInfo = new Crm.Views.NotificationInfo({
          model: notification
        });

        var notificationDetail = new Crm.Views.NotificationDetail({
          model: notification
        });

        $('#west').html(notificationInfo.render().$el);
        $('#center').html(notificationDetail.render().$el);

      } else {
        window.location.reload();
      }

      self.highlightNav("notifications");
      App.layout.show('west');
    });

    router.on('route:newNotification', function() {
      if(!App.vars.ability.can("cud", "Notification")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var notificationSearch = new Crm.Views.NotificationSearch(),
        notificationsList = new Crm.Views.NotificationsList({
          collection: Crm.collInst.notifications
        });

      $('#west').html(notificationSearch.render().$el);
      $('#center').html(notificationsList.render().$el);

      new Crm.Views.NotificationNew({
        collection: Crm.collInst.notifications
      }).render();

      self.highlightNav("notifications");
    });

    router.on('route:editNotification', function(id) {
      if(!App.vars.ability.can("cud", "Notification")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var notification = Crm.collInst.notifications.get(id),
          editNotificationForm;
          
      if(!notification && App.vars.notificationObj){
        notification = new Crm.Models.Notification( App.vars.notificationObj );
        //manual set url if model not found in collection
        notification.url = Crm.collInst.notifications.url + '/' + notification.get('id');
      }
      
      if (notification) {
        editNotificationForm = new Crm.Views.NotificationEdit({
          model: notification
        });

        $('#center').html(editNotificationForm.render().$el);
      } else {
        window.location.reload();
      }
      
      App.layout.show('west');
      self.highlightNav("notifications");
    });
    
    //users
    Crm.collInst.users = new Crm.Collections.Users();

    router.on('route:showUsers', function() {
      if(!App.vars.ability.can("read", "User")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var userSearch = new Crm.Views.UserSearch(),
        usersList = new Crm.Views.UsersList({
          collection: Crm.collInst.users
        });

      $('#west').html(userSearch.render().$el);
      $('#center').html(usersList.render().$el);

      self.highlightNav("users");
      App.layout.show('west');
    });

    router.on('route:showUser', function(id) {
      if(!App.vars.ability.can("read", "User")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var user = Crm.collInst.users.get(id);

      if(!user && App.vars.userObj){
        user = new Crm.Models.User( App.vars.userObj );
        //manual set url if model not found in collection
        user.url = Crm.collInst.users.url + '/' + user.get('id');
      }

      if(user){
        var userInfo = new Crm.Views.UserInfo({
          model: user
        });

        var userDetail = new Crm.Views.UserDetail({
          model: user
        });

        $('#west').html(userInfo.render().$el);
        $('#center').html(userDetail.render().$el);

      } else {
        window.location.reload();
      }

      self.highlightNav("users");
      App.layout.show('west');
    });

    router.on('route:newUser', function() {
      if(!App.vars.ability.can("cud", "User")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var userSearch = new Crm.Views.UserSearch(),
        usersList = new Crm.Views.UsersList({
          collection: Crm.collInst.users
        });

      $('#west').html(userSearch.render().$el);
      $('#center').html(usersList.render().$el);

      new Crm.Views.UserNew({
        collection: Crm.collInst.users
      }).render();

      self.highlightNav("users");
    });

    router.on('route:editUser', function(id) {
      if(! (App.vars.ability.can("cud", "User") || Crm.Helpers.editProfile(id)) ){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var user = Crm.collInst.users.get(id),
          editUserForm;

      if(!user && App.vars.userObj){
        user = new Crm.Models.User( App.vars.userObj );
        //manual set url if model not found in collection
        user.url = Crm.collInst.users.url + '/' + user.get('id');
      }
      
      if (user) {
        editUserForm = new Crm.Views.UserEdit({
          model: user
        });

        $('#center').html(editUserForm.render().$el);
      } else {
        window.location.reload();
      }
      
      App.layout.hide('west');
      self.highlightNav("users");
    });
    
    //reports
    Crm.collInst.users = new Crm.Collections.Users();

    router.on('route:showReports', function() {
      if(false && !App.vars.ability.can("read", "Report")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      var reportDetail = new Crm.Views.ReportDetail();

      $('#center').html(reportDetail.render().$el);

      self.highlightNav("reports");
      App.layout.hide('west');
    });
    
    //access later
    Crm.routerInst = router;
    
    // trigger route matching
    Backbone.history.start({pushState: true, root: App.vars.routeRoot + "/"});
  },
  
  unauthorizedAlert: function (){
    msgbox("You are not authorized to access this page", "danger");
    //window.location.href = App.vars.unauthorizedPath;
  },
  
  highlightNav: function(nav){
    this.leftMenu.find('li.admin-prop-info').hide();
    this.leftMenu.find('li').removeClass('active').end().find('li[data-nav="'+nav+'"]').addClass('active');
    if(nav != "notices") {
      $('#center').removeClass('previewing');
      App.layout.sizePane('west', 305);
    }
  },
  
  //Backbone View Helpers
  Helpers: {
    timeOrTimeAgo: function(str){
      var time = moment(str),
        timeStr = time.format("MMMM Do YYYY, h:mm:ss a");
      
      if((moment().diff(time, 'day') >= 2)){
        return '<span>'+ timeStr +'</span>';
        
      } else {
        return '<span title="'+ timeStr +'">'+ time.fromNow() +'</span>';
      }
    },
    prettyDuration: function(secs) {
      var hr = Math.floor(secs / 3600);
    	var min = Math.floor((secs - (hr * 3600))/60);
    	var sec = secs - (hr * 3600) - (min * 60);

    	while (min.length < 2) {min = '0' + min;}
    	while (sec.length < 2) {sec = '0' + min;}
    	if (hr) hr += ':';
    	return hr + min + ':' + sec;
    },
    
    truncate: function(str, length) {
      if(str.length > length){
        return $.trim(str).substring(0, length).split(" ").slice(0, -1).join(" ") + "...";
      } else {
        return str;
      }
    },
    
    sanitize: function(str){
      App.vars.tempDiv.html(str);
      App.vars.tempDiv.find('style, script, link').remove();
      return App.vars.tempDiv.html();
    },
    
    formatMarketingNote: function(note) {
      return note ? note.replace("</b>", "</b><p>")  + "</p>" : "";
    },
    
    isSelected: function (val1, val2) {
      return val1 == val2 ? "selected" : ""
    },

    isChecked: function (val1, val2) {
      if( _.isArray(val1) ){
        return _.contains(val1, val2) ? "checked" : "";

      } else {
        return val1 == val2 ? "checked" : "";

      }
    },

    nFormatter: function (num) {
      if (num >= 1000000000) {
        return (num / 1000000000).toFixed(1) + 'G';
      }
      if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
      }
      if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
      }
      return num;
    },

    lineBreakAndLink: function (text) {
      return text.replace(/[\r\n]{1}/g, " <br/> ").replace(/href=/g, "target='_blank' href=")
        .replace(/(http?:\/\/\S*)/g, '<a href="$1" target="_blank">$1</a>');
    },
    
    editProfile: function(id){
      return App.vars.userId == id;
    },
    
    activityIcon: function(action) {
      var cls = "";

      switch( action ){
        case "send_mail":
          cls = "fa fa-envelope";
          break;
          
        case "open_mail":
          cls = "fa fa-envelope-o";
          break;
          
        case "click_link":
          cls = "fa fa-link";
          break;
          
        case "schedule":
          cls = "fa fa-clock-o";
          break;
          
        case "import":
          cls = "fa fa-plus";
          break;
          
        case "download":
          cls = "fa fa-download";
          break;
          
        case "win":
          cls = "fa fa-trophy";
          break;
          
        case "enter":
          cls = "fa fa-sign-in";
          break;
          
        case "subscribe":
        case "subscribe_page":
        case "bulk_unsubscribe":
          cls = "fa fa-frown-o";
          break;
          
        case "unsubscribe":
        case "unsubscribe_confirm":
        case "unsubscribe_confirm_all":
        case "unsubscribe_blacklisted":
        case "unsubscribe_bounce":
        case "unsubscribe_complaint":
        case "bulk_resubscribe":
          cls = "fa fa-frown-o";
          break;
          
        case "refer":
        case "referred_by":
          cls = "fa fa-users";
          break;
          
        case "bad_email_verified":
        case "bad_email_found":
          cls = "fa fa-frown-o";
          break;
          
        case "bounce":
          cls = "fa fa-arrow-left";
          break;
          
        case "blacklist":
        case "complain":
          cls = "fa fa-exclamation-triangle";
          break;
      }
      
      return cls;
    }
    
  } // /Helpers
};