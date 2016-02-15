Crm.Views.ResidentsList = Backbone.View.extend({
  id: 'residents',
  template: JST['backbone/templates/residents/list'],

  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Resident Found" : " Residents Found";

    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  render: function(){
    var columns = [{
        name: "unit_code",
        label: "Unit #",
        cell: 'string',
        editable: false,
        sortable: false
      }, {
       name: "name",
       label: "Name",
       cell: 'string',
       editable: false,
      sortable: false
     }, {
       name: "email",
       label: "Email",
       cell: 'string',
       editable: false,
       sortable: false
     }, {
       name: "primary_phone",
       label: "Primary Phone",
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
        name: "move_in",
        label: "Move In",
        cell: 'string',
        editable: false,
        sortable: false
      }];
    
    if( !App.vars.isPropertyPage ) {
      columns.splice(0, 0, {
        name: "property_name",
        label: "Property Name",
        cell: 'string',
        editable: false,
        sortable: false
      });
    }
    
    var self = this,
       grid = new Backgrid.Grid({
         row: ClickableRow,
         columns: columns,
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
