Crm.Views.TicketsList = Backbone.View.extend({
  id: 'tickets',
  template: JST['backbone/templates/tickets/list'],

  events: {
    'click .add-new': '_new'
  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },

  _new: function () {
    var newTicket = $('#new-ticket-modal'),
      table = newTicket.find('.tablesorter');
    
    newTicket.modal('show');
    
    if(!newTicket.attr('data-init')){
      //tablesorter pager & filter
      table.tablesorter({
        sortList: [[1, 0]],
      	widgets: ['zebra', 'filter'],
        headers: {
          0: { sorter: false },
          1: { sorter: false },
          2: { sorter: false },
          3: { sorter: false }
        },
      	widgetOptions: {
      	  filter_searchDelay : 400,
      	  filter_cssFilter: 'form-control'
      	}
      });

      table.tablesorterPager({
        container: newTicket.find(".pager"),
        ajaxUrl : newTicket.attr('data-search') +  '?page={page}&{filterList:filter}&{sortList:sort}',
        ajaxProcessing: function(data){
          if(data.total == 0){
            table.find('> tbody').empty();
          }
          return [ data.total, data.rows ];
        },
        output: '{startRow} to {endRow} ({totalRows})',
        size: 10,
        savePages: false
      });
      
      newTicket.attr('data-init', 1);
    }
    
    return false;
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Ticket Found" : " Tickets Found";

    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  render: function () {
    var self = this,
      grid = new Backgrid.Grid({
        columns: [{
          name: "resident_url",
          label: "Resident ID",
          cell: 'html',
          editable: false
        }, {
          name: "id_url",
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
