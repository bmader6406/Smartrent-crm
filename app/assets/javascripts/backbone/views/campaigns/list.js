Crm.Views.CampaignsList = Backbone.View.extend({
  id: 'campaigns',
  template: JST['backbone/templates/campaigns/list'],
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.showTotal);
  },
  
  showTotal: function(){
    var total = this.collection.state.totalRecords,
      found = total == 1 ? " Notices Found" : " Notices Found";
      
    this.$('.total').text(this.collection.state.totalRecords + found);
  },
  
  render: function () {
  	var self = this,
       grid = new Backgrid.Grid({
        columns: [{
          name: "published_at",
          label: "Date/Time",
          cell: 'string',
          editable: false
        }, {
          name: "id_url",
          label: "Subject",
          cell: 'html',
          editable: false,
          sortable: false
        }, {
          name: "audience_name",
          label: "To",
          cell: 'string',
          editable: false,
          sortable: false
        }, {
          name: "actions",
          label: "Actions",
          cell: 'html',
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
