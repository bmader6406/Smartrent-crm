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

    $(document).on("click", "a[href^='/']", function(event){
      var link = $(event.currentTarget),
        href = link.attr('href'),
        target = link.attr('target'),
        sameProp = !App.vars.isPropertyPage || href.indexOf(App.vars.propertyId) > -1,
        pageReload = link.hasClass('page-reload'),
        passThrough = href.indexOf('logout') > -1 || href.indexOf('/reports') > -1 || href.indexOf('/nimda') > -1 || location.hostname.indexOf('smartrent') > -1 || target // chain 'or's for other black list routes

      // Allow shift+click for new tabs, etc.
      if (sameProp && !passThrough && !pageReload && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey){
        // Remove leading slashes and hash bangs (backward compatablility)
        var url = href.replace(/^\//,'').replace('\#\!\/','');

        // Instruct Backbone to trigger routing events
        router.navigate(url, true);
        
        //auto close left nav on click
        $('body').removeClass('left-expanded');
        
        return false
      }
    });
    
    $("form#top_nav_unit_form").submit(function(){
      $.ajax({
        url: this.action + "/units/code_" + $.trim( $('#top_unit_code').val().replace("#", "") ),
        dataType: 'json',
        success: function(data){
          if( data.id ) {
            App.vars.unitObj = data;
            router.navigate(data.show_path, true);
            
          } else {
            msgbox("No unit found. Please enter another unit number.", "danger");
          }
        },
        error: function(data) {
          msgbox("No unit found. Please enter another unit number.", "danger");
        }
      })
      return false;
    });

    //residents
    Crm.collInst.residents = new Crm.Collections.Residents();

    //residents route is shared with /residents and /properties/:property_id/resients
    // must set "id" = "propertyId" if "id" not exist

    router.on('route:showResidents', function(propertyId) {
      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }
      
      if(!propertyId && !App.vars.ability.can("admin", "Property")) {
        // PM is not allowed to view all residents
        // reload the page, backend will redirect them to the property the user has access to
        window.location.reload();
        return;
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

    router.on('route:showResident', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }

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
        //$('#resident-info .nav-details a:first').click();
        $('#resident-info .resident-details').click();

        if( window.location.hash == "#addTicket"){
          setTimeout(function(){ //wait for activity to load
            residentDetail.$('.new-ticket').click();
          }, 1200);
          
        } else if( window.location.hash == "#smartrent"){
          $('#resident-info .nav-details a[href=#smartrent]').click();
          
        } else if( window.location.hash == "#unit-history"){
          $('#resident-info .nav-details a[href=#unit-history]').click();
          
        }

      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });

    router.on('route:showResidentTickets', function(propertyId, residentId, id) {
      if(!residentId) {
        residentId = propertyId;
        propertyId = null;
      }
      if(!id) {
        id = residentId;
        residentId = null;
      }

      if(!App.vars.ability.can("read", "Resident")){
        Crm.unauthorizedAlert();
        return false;
      }

      var resident = Crm.collInst.residents.get(residentId);

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
        if(id){
          setTimeout(function(){
            var editLink = $('.edit-ticket[data-id='+ id +']:visible'),
              container = editLink.parents('.resident-box').parent();

            if(editLink[0]) {
              editLink.click();

              //hightlight
              container.animate({ backgroundColor: "#FFFDDD" }, 500, function(){
                $(this).animate({ backgroundColor: 'transparent' }, 1000);
              });

              $('#center').scrollTo(editLink, {duration: 400, offset: -20});
            }
            
          }, 1200);
        }

      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });
    router.on('route:showResidentRoommates', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }

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

    router.on('route:showResidentUnits', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }

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

        residentUnits = new Crm.Collections.ResidentUnits;
        residentUnits.url = resident.get('units_path');

        var residentUnitsList = new Crm.Views.ResidentUnitsList({
          model: resident,
          collection: residentUnits
        });

        $('#west').html(residentInfo.render().$el);
        $('#center').html(residentUnitsList.render().$el);

      } else {
        window.location.reload();
      }

      self.highlightNav("residents");
      App.layout.show('west');
    });

    router.on('route:newResident', function(propertyId) {
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

    router.on('route:editResident', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }

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

    router.on('route:showTickets', function(propertyId) {
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

    router.on('route:showTicket', function(propertyId, id) {
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

    router.on('route:newTicket', function(propertyId) {
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

    router.on('route:editTicket', function(propertyId, id) {
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

    router.on('route:showUnits', function(propertyId) {
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

    router.on('route:showUnit', function(propertyId, id) {
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
        window.location.href = '/properties/' + propertyId + '/units/' + id;
      }

      self.highlightNav("units");
      App.layout.show('west');
    });

    router.on('route:newUnit', function(propertyId) {
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

    router.on('route:editUnit', function(propertyId, id) {
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

    router.on('route:showCampaigns', function(propertyId) {
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

    router.on('route:showCampaign', function(propertyId, id) {
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

    router.on('route:newCampaign', function(propertyId) {
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

    router.on('route:editCampaign', function(propertyId, id) {
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

    router.on('route:showNotifications', function(propertyId) {
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

    router.on('route:showNotification', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }
      
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

    router.on('route:newNotification', function(propertyId) {
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

    router.on('route:editNotification', function(propertyId, id) {
      if(!id) {
        id = propertyId;
        propertyId = null;
      }
      
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

    //quick notification on top nav
    this.setupQuickNotification();

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
      if(! (App.vars.ability.can("cud", "User") || Helpers.editProfile(id)) ){
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

    router.on('route:showReports', function(propertyId) {
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
    Backbone.history.start({pushState: true, root: "/"});
    
    // global rowclicked listener
    Backbone.on("rowclicked", function (model) {
      //reset
      App.vars.residentObj = null;

      if(model.get("show_path").indexOf("import_alerts") >- 1 || model.get("page_reload") ){
        window.location.href = model.get("show_path");
        
      } else {
        router.navigate(model.get("show_path"), true);
      }
    });
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

  setupQuickNotification: function() {
    Crm.collInst.quickNotifications = new Crm.Collections.QuickNotifications;
    Crm.viewInst.quickNotificationsList = new Crm.Views.QuickNotificationsList({ collection: Crm.collInst.quickNotifications });
    Crm.viewInst.quickNotificationsList.render();

    var notificationNav = $('#notification-nav'),
      notifTemplate = '<div class="popover" id="quick-notif"><div class="arrow"></div>' +
        '<h3 class="popover-title"></h3>' +
        '<div class="popover-content">Loading...</div></div>',
      notifTitle = '<a href="'+ App.vars.notificationsPath +'" id="see-all" class="page-reload">See All</a> Notifications';

    if($.cookie("notif_sound_off")){
      notifTitle += '<a href="#" class="toggle-sound"><i class="fa fa-volume-off"></a>';

    } else {
      notifTitle += '<a href="#" class="toggle-sound"><i class="fa fa-volume-up"></a>';
    }

    notificationNav.on('click', function(){
      return false;
    });

    notificationNav.popover({
      html: true,
      title: notifTitle,
      content: "Loading...",
      template: notifTemplate,
      trigger: 'click',
      placement: 'bottom',
      container: 'body'
    });

    notificationNav.on('shown.bs.popover', function(){
      var quickNotif = $('#quick-notif');

      quickNotif.find('.popover-content').html( Crm.viewInst.quickNotificationsList.el );
      quickNotif.on('click', '.toggle-sound', function(){
        var soundOff = !$.cookie("notif_sound_off") ? 1 : "";

        if( !soundOff ) {
          quickNotif.find('.toggle-sound i').removeClass('fa-volume-off').addClass('fa-volume-up');
          
          var aSound = document.createElement('audio');
          aSound.setAttribute('src', '/ding.wav');
          aSound.play();
          
        } else {
          quickNotif.find('.toggle-sound i').removeClass('fa-volume-up').addClass('fa-volume-off');
        }

        $.cookie("notif_sound_off", soundOff, {
          expires: 365,
          path: '/'
        });

        return false;
      });
    });

  }
};
