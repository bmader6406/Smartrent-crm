Crm.Collections.Notifications = Backbone.PageableCollection.extend({
  model: Crm.Models.Notification,
  
  mode: "infinite",

  // Initial pagination states
  state: {
    pageSize: 20,
    sortKey: "created_at",
    order: 1
  },
  
  initialize: function(){
    this.url = App.vars.notificationsPath;
  },

  parseRecords: function (resp, options) {
    return resp.items;
  },
  
  parseLinks: function (resp, xhr) {
    return resp.paging;
  }

});