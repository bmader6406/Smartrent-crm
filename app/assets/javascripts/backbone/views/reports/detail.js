Crm.Views.ReportDetail = Backbone.View.extend({
  template: JST["backbone/templates/reports/detail"],
  id: 'report-detail',
  
  events: {
    "click .view-residents": "viewResidents",
    "click .export-residents": "exportResidents",
    "click .view-metrics": "viewMetrics",
    "click .export-metrics": "exportMetrics",
    "click .pagination li:not(.disabled) a": "loadMore"
  },
  
  initialize: function() {

	},
	
  render: function () {
  	this.$el.html(this.template());
  	this.setupControls();
  	
  	return this;
  },
	
	getParams: function(link) {
    var form = link.closest('form'),
      params = {
        type: link.attr('data-type')
      };
      
    switch( params.type ){
      case "emails":
        params.property_ids = form.find('select[name=property_id]').val() || [];
        params.statuses = form.find('select[name=status]').val() || [];
        params.move_in = $.trim( form.find('.report-range span').text() );
        break;

      case "birthday":
        params.property_ids = form.find('select[name=property_id]').val() || [];
        params.statuses = form.find('select[name=status]').val() || [];
        params.month = form.find('select[name=month]').val();
        break;

      case "details":
      case "summary":
        params.property_ids = form.find('select[name=property_id]').val() || [];
        params.statuses = form.find('select[name=status]').val() || [];
        params.rental_types = form.find('select[name=rental_type]').val() || [];
        break;
        
      case "comparison":
        params.property_ids = form.find('select[name=property_id]').val() || [];
        params.statuses = form.find('select[name=status]').val() || [];
        break;
    }
    
    return params;
	},
	
	viewResidents: function(ev) {
	  var self = this,
	    link = $(ev.target),
	    params = this.getParams(link);
	  
	  if(params.property_ids.length == 0 ){
	    msgbox("Please select a property", "danger");
	    
	  } else {
	    this.$el.mask('Loading...');

      $.get(App.vars.reportsPath + "/residents", params, function(){
        self.$el.unmask();
      }, 'script');
	  }
    
	  return false;
	},
	
	exportResidents: function(ev) {
	  var self = this,
	    link = $(ev.target),
	    params = this.getParams(link);
	  
    if(params.property_ids.length == 0 ){
	    msgbox("Please select a property", "danger");

	  } else {
      this.$el.mask('Please wait...');
    
      $.get(App.vars.reportsPath + "/export_residents", params, function(){
        self.$el.unmask();
      }, 'script');
    }
    
	  return false;
	},
	
	viewMetrics: function(ev) {
	  var self = this,
	    link = $(ev.target),
	    params = this.getParams(link)
	  
	  
    if(params.property_ids.length == 0 ){
	    msgbox("Please select a property", "danger");

	  } else {
      this.$el.mask('Loading...');

      $.get(App.vars.reportsPath + "/metrics", params, function(){
        self.$el.unmask();
      }, 'script');
	  }
    
	  return false;
	},
	
	exportMetrics: function(ev) {
	  var self = this,
	    link = $(ev.target),
	    params = this.getParams(link)
	  
    if(params.property_ids.length == 0 ){
	    msgbox("Please select a property", "danger");

	  } else {
      window.location.href = App.vars.reportsPath + "/export_metrics?" + $.param(params);
    }
    
	  return false;
	},
	
	loadMore: function(ev){
	  var self = this,
	    link = $(ev.target);
	  
	  this.$el.mask('Loading...');

    $.get(link.attr('href'), function(){
      self.$el.unmask();
    }, 'script');

    return false;
	},
	
  setupControls: function() {
    this.$('.selectpicker').selectpicker({
      iconBase: 'fa',
      tickIcon: 'fa-check'
    });
    
    this.$('.selectpicker').selectpicker({
      iconBase: 'fa',
      tickIcon: 'fa-check'
    });
    
    var reportRange = this.$('.report-range');;

    reportRange.daterangepicker({
        startDate: moment().subtract(30, 'days').format("MM/DD/YYYY"),
        endDate: moment().subtract(1, 'days').format("MM/DD/YYYY"),
        showDropdowns: true,
        showWeekNumbers: true,
        timePicker: false,
        timePickerIncrement: 1,
        timePicker12Hour: true,
        ranges: {
           'This Week': [moment().startOf('week'), moment().endOf('week')],
           'This Month': [moment().startOf('month'), moment().endOf('month')],
           'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')],
           'Last 3 Month': [moment().subtract(3, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
        },
        opens: 'right',
        buttonClasses: ['btn btn-default'],
        applyClass: 'btn-small btn-primary',
        cancelClass: 'btn-small',
        format: 'MM/DD/YYYY',
        separator: ' to ',
        locale: {
          applyLabel: 'Submit',
          cancelLabel: 'Clear',
          fromLabel: 'From',
          toLabel: 'To',
          customRangeLabel: 'Custom',
          daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr','Sa'],
          monthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
          firstDay: 1
        }
      },
      function(start, end, label) {
        reportRange.find('span').html(
          start.format('MMM D, YYYY') + ' - ' + end.format('MMM D, YYYY')
        );
      }
    );

    reportRange.on('apply.daterangepicker', function(ev, picker) { 
      //do something
    });
    
    App.initExportDialog();
    
    var self = this;
    
    setTimeout(function(){
      self.handleTabsClick();
    }, 100)
  },
  
  handleTabsClick: function () {
    var tabs = this.$('.nav-tabs');
    
    tabs.on('show.bs.tab', function (e) {
      var hash = $(e.target).attr('href');
      
      if(hash) window.location.hash = hash;
    });

    
    if( window.location.hash == "#report-emails"){
      tabs.find('a[href=#report-emails]').click();
      
    } else if( window.location.hash == "#report-birthday"){
      tabs.find('a[href=#report-birthday]').click();
    
    } else if( window.location.hash == "#report-details"){
      tabs.find('a[href=#report-details]').click();
    
    } else if( window.location.hash == "#report-summary"){
      tabs.find('a[href=#report-summary]').click();
      
    } else if( window.location.hash == "#report-comparison"){
      tabs.find('a[href=#report-comparison]').click();
      
    }
  }
});
