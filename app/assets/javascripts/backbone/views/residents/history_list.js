Crm.Views.UnitHistoryList = Backbone.View.extend({
  className: 'grid',
  
  events: {
  
  },
  
  render: function(){
    var columns = [{
        name: "name",
        label: "Property Name",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "unit_code",
        label: "Unit #",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "roommate",
        label: "Is Roommate?",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "status",
        label: "Status",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "move_in",
        label: "Move In",
        cell: 'string',
        editable: false,
        sortable: true
      }, {
        name: "move_out",
        label: "Move Out",
        cell: 'string',
        editable: false,
        sortable: true
      }];
    
    var self = this,
       grid = new Backgrid.Grid({
         row: ClickableRow,
         columns: columns,
         collection: this.collection
       });

    this.$el.html(grid.render().$el);

    this.collection.fetch({reset: true});

    return this;
  }
});
