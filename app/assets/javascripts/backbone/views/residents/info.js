Crm.Views.ResidentInfo = Backbone.View.extend({
  template: JST["backbone/templates/residents/info"],
  id: 'resident-info',
  
  events: {
    "click .nav-details a.tab-nav": "showTab",
    "click .default-view": "showDefaultView",
    "click .collapsible .fa": "toggleInfo",
    "click .collapsible h4": "toggleInfo",
		"click .archive": "archive",
		"scroll": "fetchMoreActivities"
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	  
	  //cache, will be reset when new resident view render
	  Crm.collInst.residentActivities = null;
	  Crm.collInst.marketingActivities = null;
	  Crm.collInst.residentProperties = null;
	  Crm.collInst.marketingProperties = null;
	  Crm.collInst.residentRoommates = null;
	},
  
  render: function () {
    this.$el.html(this.template(this.model.toJSON()));
  	return this;
  },
  
  toggleInfo: function(ev){
    var self = this,
      collapsible = $(ev.target).closest('.collapsible'),
      list = collapsible.find('> ul');
    
    if(list.is(':visible')){
      list.slideUp();
      collapsible.find('.fa-plus').show();
      collapsible.find('.fa-minus').hide();
      
    } else {
      list.slideDown();
      collapsible.find('.fa-plus').hide();
      collapsible.find('.fa-minus').show();
    }
    
    return false;
  },
  
  showTab: function(ev){
    var self = this,
      link = $(ev.target);
    
    Crm.routerInst.navigate('/residents/' + this.model.get('id'), true);
    
    $('#resident-info .nav-details .btn').removeClass('btn-primary').addClass('btn-default');
    $('#resident-info .nav-details a[href='+link.attr('href')+']').removeClass('btn-default').addClass('btn-primary');
    
    switch (link.attr('href')) {
      case '#resident-history':
        if( !Crm.collInst.residentActivities ){
          Crm.collInst.residentActivities = new Crm.Collections.Activities;
          Crm.collInst.residentActivities.url = self.model.get('activities_path') + "?history=" + "resident";
          $('#resident-history').html( new Crm.Views.ActivitiesList({ collection: Crm.collInst.residentActivities }).render().el );
        }
        
        $('#marketing-history, #resident-roommates').hide();
        $('#resident-history, #toolbar').show();
        
        break;
      
      case '#marketing-history':
        if( !Crm.collInst.marketingProperties ){
          Crm.collInst.marketingProperties = new Crm.Collections.MarketingProperties;
          Crm.collInst.marketingProperties.url = self.model.get('marketing_properties_path');
          $('#marketing-history').html( new Crm.Views.MarketingPropertiesList({ collection: Crm.collInst.marketingProperties }).render().el );
        }
        
        $('#resident-history, #resident-roommates, #toolbar').hide();
        $('#marketing-history').show();
        
        break;
      
      case '#resident-roommates':
        if( !Crm.collInst.residentRoommates ){
          Crm.collInst.residentRoommates = new Crm.Collections.ResidentRoommates;
          Crm.collInst.residentRoommates.url = self.model.get('roommates_path');
          $('#resident-roommates > div').html( new Crm.Views.ResidentRoommatesList({ collection: Crm.collInst.residentRoommates }).render().el );
        }
        
        $('#resident-history, #marketing-history, #toolbar').hide();
        $('#resident-roommates').show();
        
        break;
        
      case '#resident-properties':
        if( !Crm.collInst.residentProperties ){
          Crm.collInst.residentProperties = new Crm.Collections.ResidentProperties;
          Crm.collInst.residentProperties.url = self.model.get('properties_path');
          $('#resident-properties').html( new Crm.Views.ResidentPropertiesList({ collection: Crm.collInst.residentProperties }).render().el );
        }

        break;
    }
    
    App.layout.show('west');
    
    return false;
  },
  
  showDefaultView: function(){
    this.$('.nav-details a:first').click();
    return false;
  },
  
  fetchMoreActivities: function(){
    //console.log("fetchMoreActivities")
  },
  
  archive: function(){
    var self = this;
	  
	  bootbox.confirm("Sure you want to archive this resident?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Resident was archived successfully");
            Crm.routerInst.navigate('/residents', true);
          },
          error: function(model, response) {
            
            msgbox("There was an error, please try again.", "danger");
          }
        });
      }
    });

	  return false;
  }
});
