Crm.Views.ResidentTicketsList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled',
  id: 'resident-tickets',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addTickets);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
    var ticketView = new Crm.Views.ResidentTicket({ model: model });

		this.$el.append(ticketView.render().el);
  },
  
  addTickets: function(){
    this.$el.empty().html('<li class="well well-sm heading">Tickets</li>');
    
    if(this.collection.length == 0){
      this.$el.html('<div class="well">No Tickets Found</div>');
    } else {
      this.collection.each(this.add, this);
    }
  },
  
  remove: function (model) {
    var view = Crm.viewInst[model.toJSON()["id"]];
    if (view) view.remove();
  },
  
  render: function () {
    this.collection.fetch({reset: true});
    
  	return this;
  }
});
