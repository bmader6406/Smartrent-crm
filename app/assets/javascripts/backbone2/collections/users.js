App.Collections.Users = Backbone.PageableCollection.extend({
  model: App.Models.User,
  mode: "server",
  // Initial pagination states
  state: {
    pageSize: 15,
    sortKey: "name",
    order: 1
  },
  
  initialize: function(){
    this.url = App.vars.accountsPath;
  },

  parseState: function (resp, queryParams, state, options) {
    return {totalRecords: resp.total};
  },

  parseRecords: function (resp, options) {
    return resp.items;
  }
});