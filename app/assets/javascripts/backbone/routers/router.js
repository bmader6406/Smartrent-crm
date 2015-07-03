Crm.Router = Backbone.Router.extend({
  routes: {
    '': 'home',
    
    'residents(/)': 'showResidents',
    'residents/new(/)': 'newResident',
    'residents/:id/edit(/)': 'editResident',
    'residents/:id(/)': 'showResident',
    'residents/:id/tickets(/)': 'showResidentTickets',
    'residents/:id/roommates(/)': 'showResidentRoommates',
    'residents/:id/properties(/)': 'showResidentProperties',
     
    'properties(/)': 'showProperties',
    'properties/new(/)': 'newProperty',
    'properties/:id/edit(/)': 'editProperty',
    'properties/:id(/)': 'showProperty',
    'properties/:id/info(/)': 'showProperty',
     
    'tickets(/)': 'showTickets',
    'tickets/new(/)': 'newTicket',
    'tickets/:id/edit(/)': 'editTicket',
    'tickets/:id(/)': 'showTicket',
    
    'notifications(/)': 'showNotifications',
    'notifications/new(/)': 'newNotification',
    'notifications/edit(/)': 'editNotification',
    'notifications/:id(/)': 'showNotification',
     
    'units(/)': 'showUnits',
    'units/new(/)': 'newUnit',
    'units/:id/edit(/)': 'editUnit',
    'units/:id(/)': 'showUnit',
    
    'notices(/)': 'showCampaigns',
    'notices/new(/)': 'newCampaign',
    'notices/:id/edit(/)': 'editCampaign',
    'notices/:id(/)': 'showCampaign',
    
    'users(/)': 'showUsers',
    'users/new(/)': 'newUser',
    'users/:id/edit(/)': 'editUser',
    'users/:id(/)': 'showUser',
    
    'reports(/)': 'showReports'
  }
});
