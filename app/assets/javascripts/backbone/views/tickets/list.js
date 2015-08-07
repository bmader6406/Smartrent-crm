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
      form = newTicket.find('form');
    
    newTicket.modal('show');
    form.find(':text').focus();
    
    if(!form.attr('data-init')){
      form.on('submit', function(){
        var searchVal = $.trim(form.find(':text').val());
        
        if(searchVal){
          form.find('.search').text('Searching...');

          $.get(form.attr('action'), {search: searchVal }, function(data){
            if(data.resident_path){
              newTicket.modal('hide');
              Crm.routerInst.navigate(data.resident_path.replace(/crm\/\d+\//, '').replace(/^\//,'').replace('\#\!\/',''), true);
              
            } else {
              msgbox("No Residents Found!");

            }

            form.find('.search').text('Search');

          }, 'json');
        } else {
          msgbox('Please enter resident ID or resident email!', 'danger');
        }
        
        return false;
      });
      
      form.attr('data-init', 1);
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
