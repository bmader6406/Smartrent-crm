Crm.Collections.Units = Backbone.PageableCollection.extend({
  model: Crm.Models.Unit,
  mode: "server",
  // Initial pagination states
  state: {
    pageSize: 15,
    sortKey: "name",
    order: 1
  },
  
  initialize: function(){
    this.url = "/units";
  },

  parseState: function (resp, queryParams, state, options) {
    return {totalRecords: resp.total};
  },

  parseRecords: function (resp, options) {
    return resp.items;
  }
});