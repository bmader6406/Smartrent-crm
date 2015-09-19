Crm.Views.ResidentInfo = Backbone.View.extend({
  template: JST["backbone/templates/residents/info"],
  id: 'resident-info',

  events: {
    "click .nav-details a.tab-nav": "showTab",
    "click .default-view": "showDefaultView",
    "click .collapsible .fa": "toggleInfo",
    "click .collapsible h4": "toggleInfo",
    "click .archive": "archive",
    "click .view-smartrent": "viewSmartrent",
    "click .resident-details": "viewResidentDetails",
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

    Crm.routerInst.navigate(App.vars.routeRoot + '/residents/' + this.model.get('id'), true);

    $('#resident-info .nav-details .btn').removeClass('btn-primary').addClass('btn-default');
    $('#resident-info .nav-details a[href='+link.attr('href')+']').removeClass('btn-default').addClass('btn-primary');

    switch (link.attr('href')) {
      case '#resident-history':
        if( !Crm.collInst.residentActivities ){
          Crm.collInst.residentActivities = new Crm.Collections.Activities;
          Crm.collInst.residentActivities.url = self.model.get('activities_path') + "?history=" + "resident";
          $('#resident-history').html( new Crm.Views.ActivitiesList({ collection: Crm.collInst.residentActivities }).render().el );
        }

        $('#marketing-history, #resident-roommates, #smartrent, #resident-details').hide();
        $('#resident-history, #toolbar').show();

        // load smartrent info in background
        if (this.model.get('smartrent') && App.vars.isCrm && App.vars.isSmartrent) {
          $.getJSON(this.model.get('smartrent_path'), function(data){
            self.$('.smartrent-info').replaceWith( JST["backbone/templates/residents/smartrent_info"](data) );
            self.$('.smartrent-info').hide();
          });
        }

        break;

      /*case '#marketing-history':
        if( !Crm.collInst.marketingProperties ){
          Crm.collInst.marketingProperties = new Crm.Collections.MarketingProperties;
          Crm.collInst.marketingProperties.url = self.model.get('marketing_properties_path');
          $('#marketing-history').html( new Crm.Views.MarketingPropertiesList({ collection: Crm.collInst.marketingProperties }).render().el );
        }

        $('#resident-history, #resident-roommates, #smartrent, #toolbar').hide();
        $('#marketing-history').show();

        break;*/

      case '#resident-roommates':
        if( !Crm.collInst.residentRoommates ){
          Crm.collInst.residentRoommates = new Crm.Collections.ResidentRoommates;
          Crm.collInst.residentRoommates.url = self.model.get('roommates_path');
          $('#resident-roommates > div').html( new Crm.Views.ResidentRoommatesList({ collection: Crm.collInst.residentRoommates }).render().el );
        }

        $('#resident-history, #marketing-history, #smartrent, #toolbar').hide();
        $('#resident-roommates').show();

        break;

      case '#resident-properties':
        if( !Crm.collInst.residentProperties ){
          Crm.collInst.residentProperties = new Crm.Collections.ResidentProperties;
          Crm.collInst.residentProperties.url = self.model.get('properties_path');
          $('#resident-properties').html( new Crm.Views.ResidentPropertiesList({ collection: Crm.collInst.residentProperties }).render().el );
        }

        break;

      case '#smartrent':
        var smartrent = $('#smartrent');

        if (this.model.get('smartrent')) {
          $.getJSON(this.model.get('smartrent_path'), function(data){
            smartrent.html( new Crm.Views.Smartrent({ model: data }).render().el );

            self.$('.smartrent-info').replaceWith( JST["backbone/templates/residents/smartrent_info"](data) );
            self.$('.smartrent-info').show();
          });
        } else {
          smartrent.html('<div class="well"> No Smartrent Record Found! <br><br> Smartrent record will be created on '+ this.model.get('move_in') +' </div>');
        }

        $('#resident-history, #marketing-history, #resident-roommates, #toolbar').hide();
        smartrent.show();

        break;
    }

    App.layout.show('west');

    return false;
  },
  viewResidentDetails: function(){
    $('#resident-history, #marketing-history, #resident-roommates, #toolbar, #smartrent').hide();
    $('#resident-info .nav-details .btn').removeClass('btn-primary').addClass('btn-default');
    $('#resident-history, #marketing-history, #resident-roommates, #toolbar').hide();
    $('#resident-details').html( JST["backbone/templates/residents/resident-detail"](this.model.toJSON()) );
    $('#resident-details').show();
    var self = this;
    $.getJSON(this.model.get('smartrent_path'), function(data){
      $('.smartrent-info').replaceWith( JST["backbone/templates/residents/smartrent_info"](data) );
      $('.smartrent-info').show();
    });
    $('#resident-details .view-smartrent').click(function(){
      $('.nav-details a[href="#smartrent"]').click();
    });
  },

  showDefaultView: function(){
    debugger;
    this.$('.nav-details a:first').click();
    return false;
  },

  fetchMoreActivities: function(){
    //console.log("fetchMoreActivities")
  },

  viewSmartrent: function(){
    this.$('.nav-details a[href="#smartrent"]').click();
    return false;
  },

  archive: function(){
    var self = this;

	  bootbox.confirm("Sure you want to archive this resident?", function(result) {
      if (result) {
        self.model.destroy({
          success: function(model, response) {
            msgbox("Resident was archived successfully");
            Crm.routerInst.navigate(App.vars.routeRoot + '/residents', true);
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
