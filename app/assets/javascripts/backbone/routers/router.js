Crm.Router = Backbone.Router.extend({
  routes: {
    '': 'home',

    'accounts(/)': 'showUsers',
    'accounts/new(/)': 'newUser',
    'accounts/:id/edit(/)': 'editUser',
    'accounts/:id(/)': 'showUser',

    'properties(/)': 'showProperties',
    'properties/new(/)': 'newProperty',
    'properties/:id/edit(/)': 'editProperty',
    'properties/:id(/)': 'showProperty',
    'properties/:id/info(/)': 'showProperty',

    'properties/:property_id/residents(/)': 'showResidents',
    'properties/:property_id/residents/new(/)': 'newResident',
    'properties/:property_id/residents/:id/edit(/)': 'editResident',
    'properties/:property_id/residents/:id(/)': 'showResident',
    'properties/:property_id/residents/:resident_id/tickets/:id(/)': 'showResidentTickets',
    'properties/:property_id/residents/:id/tickets(/)': 'showResidentTickets',
    'properties/:property_id/residents/:id/roommates(/)': 'showResidentRoommates',
    'properties/:property_id/residents/:id/properties(/)': 'showResidentProperties',

    'properties/:property_id/tickets(/)': 'showTickets',
    'properties/:property_id/tickets/new(/)': 'newTicket',
    'properties/:property_id/tickets/:id/edit(/)': 'editTicket',
    'properties/:property_id/tickets/:id(/)': 'showTicket',

    'properties/:property_id/units(/)': 'showUnits',
    'properties/:property_id/units/new(/)': 'newUnit',
    'properties/:property_id/units/:id/edit(/)': 'editUnit',
    'properties/:property_id/units/:id(/)': 'showUnit',

    'properties/:property_id/notices(/)': 'showCampaigns',
    'properties/:property_id/notices/new(/)': 'newCampaign',
    'properties/:property_id/notices/:id/edit(/)': 'editCampaign',
    'properties/:property_id/notices/:id(/)': 'showCampaign',

    'properties/:property_id/reports(/)': 'showReports',

    'residents(/)': 'showResidents',
    'residents/new(/)': 'newResident',
    'residents/:id/edit(/)': 'editResident',
    'residents/:id(/)': 'showResident',
    'residents/:id/tickets(/)': 'showResidentTickets',
    'residents/:id/roommates(/)': 'showResidentRoommates',
    'residents/:id/properties(/)': 'showResidentProperties',

    'reports(/)': 'showReports',

    'notifications(/)': 'showNotifications',
    'notifications/new(/)': 'newNotification',
    'notifications/edit(/)': 'editNotification',
    'notifications/:id(/)': 'showNotification'
  }
});
