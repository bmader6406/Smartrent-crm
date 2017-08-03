Crm.Views.ResidentTicket = Backbone.View.extend({
  template: JST["backbone/templates/residents/ticket"],
  tagName: 'li',
  
  events: {
    "click .status-dd li a": "setStatus",
    "click .edit-ticket": "edit"
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	  this.listenTo(this.model, 'rerender', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  setStatus: function(ev){
    var link = $(ev.target),
      statusDd = link.parents('.status-dd'),
      statusSelect = statusDd.find('#status');
    
    if( !this.$('#ticket-wrap')[0] ){ //show edit form
      this.edit();
      this.$('.status-dd li a[data-status="'+ link.attr('data-status') +'"]').click();
      
    } else { //change status
      statusDd.find('> span').text( link.text() );
      statusDd.attr('class', 'status-dd ' + link.attr('data-status').replace(" ", "-"));
      statusSelect.val( link.attr('data-status') );
    }
  },
  
  edit: function() {
    var ticket = this.model;
    //manual set model url
    ticket.url = Crm.collInst.tickets.url + '/' + ticket.get('id');
    //removing entity names in description
    description = ticket["attributes"]["description"];
    ticket["attributes"]["description"] = App.Utils.htmlDecode(description);
    this.$el.html( new Crm.Views.TicketEdit({ model: ticket }).render().el );
    
    return false;
  }
  
});
