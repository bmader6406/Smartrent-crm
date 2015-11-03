Crm.Views.ResidentUnitsList = Backbone.View.extend({
  tagName: 'ul',
  className: 'list-unstyled',
  id: 'resident-units',
  
  events: {
    
  },
  
  initialize: function () {
    this.listenTo(this.collection, 'reset', this.addUnits);
    this.listenTo(this.collection, 'add', this.add);
  },
  
  add: function (model) {
    var self = this,
      propertyView = new Crm.Views.ResidentUnit({ model: model }),
      unitEl = propertyView.render().el;
    
    if(location.href.indexOf('_' + model.get('unit_id')) > -1) {
      $(unitEl).find('.resident-box').addClass('current');
    }

    self.$('#'+ model.get('status').toLowerCase() +'-units').append(unitEl);
    self.$('.nav-pills a[href="#'+ model.get('status').toLowerCase() +'-units"]').show();
  },
  
  addUnits: function(){
    var self = this;
    
    this.$el.empty().html( JST["backbone/templates/residents/units"]() );
    
    if(this.collection.length == 0){
      this.$el.html('<div class="well">No Resident Units Found</div>');
      
    } else {
      this.collection.each(this.add, this);
      
      var listId = self.$('.resident-box.current').parent().parent().attr('id');
      self.$('.nav-pills a[href="#'+ listId +'"]').click();
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
