Crm.Views.UnitDetail = Backbone.View.extend({
  template: JST["backbone/templates/units/detail"],
  id: 'unit-detail',

  events: {
    //'click .add-new-ticket': 'newTicket'
  },

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
        },
        parseState: function (resp, queryParams, state, options) {
          return {totalRecords: resp.total};
        },
        state: {
          pageSize: 5,
          sortKey: "request_date",
        }
      });
      var unitTicketCollection = new UnitTicketCollection(),
        grid = new Backgrid.Grid({
        row: ClickableRow,
        columns: [{
          name: "description",
          label: "Description",
          cell: 'html',
          editable: false,
          formatter: _.extend({}, Backgrid.CellFormatter.prototype, {
            fromRaw: function (rawValue, model) {
              return rawValue.trunc(10);
            }
          })
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
    this.unitTicketCollection = unitTicketCollection;

  	return this;
  },
  newTicket: function(ev){
    var self = this;
    Crm.routerInst.navigate(this.model.get("add_ticket_path"))
    /*this.formWrap = this.$('#form-wrap');
    if( !this.ticketForm ) {
      Crm.collInst.residentTickets = new Crm.Collections.ResidentTickets;
      Crm.collInst.residentTickets.url = App.vars.routeRoot + "/tickets";

      this.ticketForm = new Crm.Views.TicketNew({
        collection: Crm.collInst.residentTickets
      });
      this.ticketForm.resident = new Crm.Models.Resident(this.model.get("primary_resident") );

      this.formWrap.append( this.ticketForm.render().el );
    }

    if( this.$('#ticket-wrap:visible')[0] ){
      this.$('#ticket-wrap').slideUp();
      this.$('.add-new-ticket').removeClass('selected');

    } else {
      this.formWrap.find('> div').hide();
      this.$('.add-new-ticket').removeClass('selected').end().find('.new-ticket').addClass('selected');
      this.$('#ticket-wrap').slideDown(function(){
        $('#center').scrollTo('#form-wrap', {duration: 400});
      });
    }
    App.vars.unit = {};
    App.vars.unit.isTicket = true;
    App.vars.unit.successCallBack = function(){
      self.unitTicketCollection.fetch({reset: true});
    }
    */

  },
});
