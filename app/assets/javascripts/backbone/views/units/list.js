Crm.Views.UnitsList = Backbone.View.extend({
  id: 'units',
  template: JST['backbone/templates/units/list'],
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Unit Found" : " Units Found";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },
  
  render: function () {
  	var self = this,
       grid = new Backgrid.Grid({
        columns: [{
          name: "id_url",
          label: "Unit ID",
          cell: 'html',
          editable: false
        }, {
          name: "code",
          label: "Code",
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
          rewind: null,
          back: null,
          forward: null,
          fastForward: null
        }
      });

    this.$el.html(this.template());

    this.$(".grid").append(grid.render().$el);
    this.$(".paginator").append(paginator.render().$el);

    this.collection.fetch({reset: true});

    return this;
  }
});
