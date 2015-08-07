Crm.Views.PropertiesList = Backbone.View.extend({
  id: 'properties',
  template: JST['backbone/templates/properties/list'],

  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Property Found" : " Properties Found";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },
  
  render: function(){
    var self = this,
      grid = new Backgrid.Grid({
        columns: [{
          name: "name_url",
          label: "Name",
          cell: 'html',
          editable: false
        }, {
          name: "city",
          label: "City",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "state",
          label: "State",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "zip",
          label: "ZIP",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "property_number",
          label: "Property Number",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "l2l_property_id",
          label: "L2L ID",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "yardi_property_id",
          label: "Yardi ID",
          cell: 'string',
          editable: false,
          sortable: false
        }],
        collection: self.collection
      }),

      paginator = new Backgrid.Extension.Paginator({
        collection: self.collection,
        controls: {
          fastForward: null,
          rewind: null
        },
        windowSize: 5
      });

    this.$el.html(this.template());

    this.$(".grid").append(grid.render().$el);
    this.$(".paginator").append(paginator.render().$el);

    this.collection.fetch({reset: true});
    
    return this;
  }
});