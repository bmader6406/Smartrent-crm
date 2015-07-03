Crm.Views.ResidentsList = Backbone.View.extend({
  id: 'residents',
  template: JST['backbone/templates/residents/list'],

  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Resident Found" : " Residents Found";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },
  
  render: function(){
    var self = this,
       grid = new Backgrid.Grid({
         columns: [{
            name: "id",
            label: "Resident ID",
            cell: 'string',
            editable: false
          }, {
           name: "name_url",
           label: "Name",
           cell: 'html',
           editable: false
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