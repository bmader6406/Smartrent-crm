Crm.Collections.Notifications = Backbone.PageableCollection.extend({
  model: Crm.Models.Notification,
  mode: "server",
  // Initial pagination states
  state: {
    pageSize: 15,
    sortKey: "created_at",
    order: 1
  },
  
  queryParams: {
    state: "pending"
  },
  
  initialize: function(){
    this.url = App.vars.notificationsPath;
  },

  parseState: function (resp, queryParams, state, options) {
    return {totalRecords: resp.total};
  },

  parseRecords: function (resp, options) {
    return resp.items;
  }
});