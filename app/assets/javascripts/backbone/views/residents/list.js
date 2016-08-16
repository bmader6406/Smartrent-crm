Crm.Views.ResidentsList = Backbone.View.extend({
  id: 'residents',
  template: JST['backbone/templates/residents/list'],

  events: {

  },

  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);

    // fix multiple sort icon
    this.listenTo( this.collection, "backgrid:sort", function (sort) {
      sort.collection.chain().filter( function ( model ) {
        return model.cid !== sort.cid;
      }).each( function ( model ) {
        model.set( "direction", null );
      });
    });
  },

  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Resident Found" : " Residents Found";

    this.$('.total').text(this.collection.state.totalRecords + found);
  },

  render: function(){
    var columns = [{
         name: "name",
         label: "Name",
         cell: 'string',
         editable: false,
         sortable: true
       }, {
        name: "unit_code",
        label: "Unit #",
        cell: 'string',
        editable: false,
        sortable: false
      }, {
       name: "email",
       label: "Email",
       cell: 'string',
       editable: false,
       sortable: true
     }, {
       name: "primary_phone",
       label: "Primary Phone",
       cell: 'string',
       editable: false,
       sortable: false,
       renderable: false
     }, {
        name: "status",
        label: "Status",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "roommate_text",
        label: "Roommate?",
        cell: 'string',
        editable: false,
        sortable: true,
        renderable: App.vars.isPropertyPage
      }, {
        name: "move_in",
        label: "Move In",
        cell: 'string',
        editable: false,
        sortable: true
      }];
    
    if( !App.vars.isPropertyPage ) {
      columns.splice(1, 0, {
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
         goBackFirstOnSort: false,
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
