Crm.Views.NotificationsList = Backbone.View.extend({
  id: 'notifications',
  template: JST['backbone/templates/notifications/list'],

  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = "";
    
    switch( $('#notification-state').val() ){
      case "pending":
        found = total == 1 ? " Pending Message" : " Pending Messages";
        break;
      
      case "acknowledged":
        found = total == 1 ? " Acknowledged Message" : " Acknowledged Messages";
        break;
        
      case "replied":
        found = total == 1 ? " Replied Message" : " Replied Messages";
        break;
        
      default:
        found = total == 1 ? "Message" : " Messages";
    }
    
    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  render: function () {
    var ClickableRow = Backgrid.Row.extend({
      events: {
        "click": "onClick"
      },
      onClick: function () {
        Backbone.trigger("rowclicked", this.model);
      }
    });

  	var self = this,
       grid = new Backgrid.Grid({
        row: ClickableRow,
        columns: [{
          name: "created_time",
          label: "Date & Time",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "property_name",
          label: "Property Name",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "unit_code",
          label: "Unit #",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "resident_name",
          label: "Resident",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "subject",
          label: "Subject",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "message",
          label: "Message",
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
