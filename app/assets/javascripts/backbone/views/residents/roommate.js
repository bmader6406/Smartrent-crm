Crm.Views.Roommate = Backbone.View.extend({
  template: JST["backbone/templates/residents/roommate"],
  tagName: 'li',
  
  events: {
    "click .edit-roommate": "edit"
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	  this.listenTo(this.model, 'rerender', this.render);
	},
  
  render: function () {
  	this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  edit: function() {
    var roommate = this.model;
    //manual set model url
    roommate.url = Crm.collInst.roommates.url + '/' + roommate.get('id');
    
    this.$el.html( new Crm.Views.RoommateEdit({ model: roommate }).render().el );
    
    return false;
  }
  
});
