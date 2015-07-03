var HtmlCell = Backgrid.HtmlCell = Backgrid.Cell.extend({
  /** @property */
  className: "html-cell",
  initialize: function() {
    Backgrid.Cell.prototype.initialize.apply(this, arguments);
  },
  render: function() {
    this.$el.empty();
    var rawValue = this.model.get(this.column.get("name"));
    var formattedValue = this.formatter.fromRaw(rawValue, this.model);
    this.$el.append(formattedValue);
    this.delegateEvents();
    return this;
  }
});

var App = {
  vars: {},
  
  initPageLayout: function(eastSize, westSize, resizeFunc, hideWest, showEast){
    var viewport = $('#viewport'),
      body = viewport.parent(),
      opts = {
    	  resizable: false,
    	  closable: false,
    	  east__size: eastSize || 356,
    	  west__size: westSize || 305,
    	  west__initClosed: hideWest,
    	  east__initClosed: !showEast,
    	  spacing_open: 0,
        spacing_closed: 0,
        center__onresize: function(){
          if(resizeFunc) resizeFunc();
        },
        fxName: 'none',
  			togglerContent_open:	'<div class="ui-icon"></div>',
        togglerContent_closed:	'<div class="ui-icon"></div>'
    	},
      leftExpanded = true;
    
    this.viewport = viewport;
    this.layout = viewport.layout(opts);
  	
  	//left-nav expand/collapse
  	viewport.on('click', '#hamburger', function(){
  	  var t = $(this);
  	  
  	  if(t.attr('data-expanded')){
  	    body.removeClass('left-expanded');
  	    t.removeAttr('data-expanded');
  	    t.find('i').attr('class', 'fa fa-bars');
  	    leftExpanded = false;
  	  } else {
  	    body.addClass('left-expanded');
  	    t.attr('data-expanded', 1);
  	    t.find('i').attr('class', 'fa fa-angle-left');
  	    leftExpanded = true;
  	  }
  	  
  	  return false;
  	});
  	
  	//prop filter
  	var propertyDd = $('#property-dd'),
      listGroup = propertyDd.find('.list-group');

    propertyDd.find('.form-inline :text').fastLiveFilter(propertyDd.find('.items'), {
      timeout: 200
    });

    propertyDd.on('shown.bs.dropdown', function () {
      setTimeout(function(){
        propertyDd.find('.form-inline :text').focus();
      }, 100);

    }).on('click', '.dropdown-menu', function(e){
      e.stopPropagation();

    });
    
    var scrolling = false;
    
    propertyDd.find('.scroller').mCustomScrollbar({
      autoHideScrollbar:true,
      autoDraggerLength: false,
      scrollInertia: 1500,
      advanced:{
        updateOnContentResize: true
      },
      theme:"light-thin",
      callbacks:{
        onScroll: function(){
          scrolling = false;
        },
        whileScrolling: function(){
          scrolling = true;
        }
      }
    });
    
    Crm.initialize();
    
    // close left nav on escape, viewport click
    $(document).on('keydown', function(e) {
      if(leftExpanded && e.which == 27) {
        $('#hamburger[data-expanded=1]').click();
      }
    }).on('click', function(e){
      if(leftExpanded && $(e.target).parents('#viewport')[0]){
        $('#hamburger[data-expanded=1]').click();
      }
    });
  },
  
  initAssetManager: function(){
    this.assetDialog = $('#asset-dialog');
    
    this.assetDialog.on('show.bs.modal', function (e) {
      if(!App.assetDialog.find('#gallery')[0]){ //first load
        App.assetDialog.mask('loading...');

        $.get(App.pageAssetUrl, function(){
          App.assetDialog.unmask();
        }, 'script');
      }
      
    }).on('hide.bs.modal', function (e) {
      App.vars.uploadTarget = "";
    });
    
  },
  
  initExportDialog: function(){
    if(!this.exportDialog) {
      this.exportDialog = $('#export-dialog');
      
      this.exportDialog.on('show.bs.modal', function (e) {
        // do something
      }).on('hide.bs.modal', function (e) {
        // do something
      });

      this.exportDialog.on('click', '#download-btn', function(){
        var btn = $(this),
    	    email = btn.prev().val(),
    	    dialog = $("#alert");

        App.exportDialog.mask("Please wait...");

        if(App.validateEmail(email) ){
          $.get(App.exportDialog.attr("data-url"), {recipient: email}, function(){
      	    App.exportDialog.unmask();
      	  }, 'script');

        }else {
          msgbox("Please enter a valid email");
          App.exportDialog.unmask();
        }

    	  return false;
      }).on('keyup', 'input:text', function(ev){

        if(ev.which == 13){
          $(this).next().click();
          return false;
        }
      });
    }
  },
  
  validateEmail: function(email){
    return /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(email);
  },

  validateUrl: function(url){
    var reg = /^(https?|ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i;
		return reg.test(url);
  }
}

//global functions

function msgbox(msg, type){
  $('#notify').notify({
    type: type || "success",
    message: { html: msg }
  }).show();
};