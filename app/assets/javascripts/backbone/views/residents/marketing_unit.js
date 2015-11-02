Crm.Views.MarketingUnit = Backbone.View.extend({
  template: JST["backbone/templates/residents/marketing_unit"],
  tagName: 'li',
  
  events: {
    "click .view-history": "viewHistory"
  },

  initialize: function() {
	  this.listenTo(this.model, 'change', this.render);
	},
  
  render: function () {
    this.$el.html('Loading...');
  	this.$el.html(this.template(this.model.toJSON()));
    
    this.setupStatusPopover();
  	
  	return this;
  },
  
  setupStatusPopover: function(){
    var self = this;
    
    this.$el.hoverIntent({
      over: function () {
        var t = $(this);
        
        if(t.data('setup')) {
          t.popover("show");
          return false;
        }
        
        t.popover({
          animation: false,
          html: true,
          title: "Status History",
          trigger: 'manual',
          container: 'body',
          placement: 'left',
          content: '<div>Loading...</div>',
          template: '<div class="popover prop-status"><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
        }).on('shown.bs.popover', function () {
          var popover = $('.popover:visible:last');

          $.get(self.model.get('statuses_path'), function(data){
            popover.find('.popover-content').html( JST["backbone/templates/residents/marketing_statuses"]({statuses: data}) );
            
          }, 'json').fail(function(){
            msgbox("There was an error while loading the status, please try again", "danger");
            residentBox.unmask();
          });
        });

        t.data('setup', 1);
        t.popover("show"); //manual trigger

        $(".popover:visible").on("mouseleave", function () {
          t.popover('hide');
        });
      },
      out: function(){
        var t = $(this);
        
        setTimeout(function () {
          if (!$(".popover:hover").length) {
            t.popover("hide");
          }
        }, 100);
      },
      selector: '.status-popover',
      timeout: 300
    })
  },
  
  viewHistory: function(ev){ //obsolete (x-ray will handle this)
    var self = this,
      link = $(ev.target),
      residentBox = link.closest('.resident-box'),
      propHistory = residentBox.find('.prop-history');
      
    if(!link.attr("data-loaded")){
      link.attr("data-loaded", 1);
      residentBox.mask('Loading...');
      
      marketingActivities = new Crm.Collections.Activities;
      marketingActivities.url = self.model.get('activities_path');
      
      self.listenTo(marketingActivities, 'reset', function(){ 
        residentBox.unmask();
      });
      
      propHistory.html( new Crm.Views.ActivitiesList({ collection: marketingActivities }).render().el );
      propHistory.slideDown();
      
      link.data("opened", 1).html('Hide Property Marketing Activity <i class="fa fa-angle-up"></i>');
      
    } else {
      if(link.data("opened")){
        link.data("opened", 0).html('Show Property Marketing Activity <i class="fa fa-angle-down"></i>');
        propHistory.slideUp();

      }else {
        link.data("opened", 1).html('Hide Property Marketing Activity <i class="fa fa-angle-up"></i>');
        propHistory.slideDown();
      }
    }
    
    return false;
  }
  
});
