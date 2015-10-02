Crm.Views.UnitDetail = Backbone.View.extend({
  template: JST["backbone/templates/units/detail"],
  id: 'unit-detail',

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},

  render: function () {
  	var self = this,
     ClickableRow = Backgrid.Row.extend({
      events: {
        "click": "onClick"
      },
      onClick: function () {
        Backbone.trigger("rowclicked", this.model);
      }
    });
  	this.$el.html(this.template(this.model.toJSON()));

  	//load unit residents
  	$.get(this.model.get('residents_path'), function(residents){
  	  self.$('#unit-resident-list').html( JST["backbone/templates/units/residents"]({residents: residents}) );
  	}, 'json');

    //Load Tickets
      var UnitTicketCollection = Backbone.PageableCollection.extend({
        url: App.vars.routeRoot + "/units/" + self.model.get("id") + "/tickets",
        mode: "server",
        model: Crm.Models.Ticket,
        parseRecords: function (resp, options) {
          return resp.items;
        }
      });
      var unitTicketCollection = new UnitTicketCollection(),
        grid = new Backgrid.Grid({
        row: ClickableRow,
        columns: [{
          name: "resident_id",
          label: "Resident ID",
          cell: 'html',
          editable: false
        }, {
          name: "id",
          label: "Ticket ID",
          cell: 'html',
          editable: false
        }, {
          name: "status",
          label: "Status",
          cell: 'html',
          editable: false,
          sortable: false,
          formatter: _.extend({}, Backgrid.CellFormatter.prototype, {
            fromRaw: function (rawValue, model) {
              return '<span class="status '+ rawValue.replace(" ", "-") +'">' + rawValue + '</span>';
            }
          })
        }, {
          name: "first_name",
          label: "First Name",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "created_date",
          label: "Request Date",
          cell: 'string',
          editable: false,
          sortable: false
        }],
        collection: unitTicketCollection
      }),

      paginator = new Backgrid.Extension.Paginator({
        collection: unitTicketCollection,
        controls: {
          fastForward: null,
          rewind: null
        },
        windowSize: 5
      });


    this.$(".grid").append(grid.render().$el);
    this.$(".paginator").append(paginator.render().$el);

    this.listenTo(unitTicketCollection, 'request', App.showMask);
    this.listenTo(unitTicketCollection, 'sync', App.hideMask);
    unitTicketCollection.fetch({reset: true});

  	return this;
  }
});
