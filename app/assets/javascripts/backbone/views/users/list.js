Crm.Views.UsersList = Backbone.View.extend({
  id: 'users',
  template: JST['backbone/templates/users/list'],
  
  events: {

  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
    this.listenTo(this.collection, 'request', App.showMask);
    this.listenTo(this.collection, 'sync', App.hideMask);
  },
  
  remove: function (model) {
    var view = Crm.viewInst[model.toJSON()["id"]];
    if (view) view.remove();
  },

  add: function (model) {
    //placeholder
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " User Found" : " Users Found";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },
  
  render: function () {
  	var self = this,
       grid = new Backgrid.Grid({
        row: ClickableRow,
        columns: [{
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
          name: "role_name",
          label: "Role",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "authorized_properties",
          label: "Authorization",
          cell: 'html',
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
