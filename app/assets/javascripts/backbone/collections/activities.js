Crm.Collections.Activities = Backbone.PageableCollection.extend({
  model: Crm.Models.Activity,
  mode: "infinite",

  // Initial pagination states
  state: {
    pageSize: 20,
    sortKey: "created_at",
    order: 1
  },
  
  initialize: function(){
    
  },
  
  parseState: function (resp, queryParams, state, options) {
    return {
      nextLink: resp.paging.next
    };
  },
  
  parseRecords: function (resp, options) {
    return resp.items;
  },
  
  parseLinks: function (resp, xhr) {
    return resp.paging;
  }
});
