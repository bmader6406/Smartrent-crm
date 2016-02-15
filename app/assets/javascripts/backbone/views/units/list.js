Crm.Views.UnitsList = Backbone.View.extend({
  id: 'units',
  template: JST['backbone/templates/units/list'],

  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Unit Found" : " Units Found";

    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  render: function () {
  	var self = this,
       grid = new Backgrid.Grid({
        row: ClickableRow,
        columns: [{
          name: "code",
          label: "Unit #",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "bed",
          label: "Bed",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "bath",
          label: "Bath",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "sq_ft",
          label: "Sq. Ft.",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "status",
          label: "Status",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "rental_type",
          label: "Rental Type",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "description",
          label: "Description",
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
