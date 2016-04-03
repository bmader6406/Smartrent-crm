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
        togglerContent_open:  '<div class="ui-icon"></div>',
        togglerContent_closed:  '<div class="ui-icon"></div>'
      },
      leftExpanded = true;

    this.viewport = viewport;
    this.layout = viewport.layout(opts);

    //left-nav expand/collapse
    var body = $('body');
    $('#top-nav .navbar-brand, #left-nav .app-name, #mask').on('click', function(){
      if( body.hasClass('left-expanded') ) {
        body.removeClass('left-expanded');

      } else {
        body.addClass('left-expanded');
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

    if (! App.vars.srApp ) {
      Crm.initialize();
    }
    
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
  },
  
  getEmailFromStr: function (email){
    try{ email = email.match(/<\S*>/)[0].replace(/<|>/g, ''); }catch(ex){} 
    return email;
  },
  
  getInvalidEmails: function(str){
    var emails = str.split(","),
      invalidEmails = [];
      
    _.each(emails, function(e){
      if ( e && !App.validateEmail( App.getEmailFromStr(e.trim()) )) {
        invalidEmails.push(e.trim())
      }
    });
    
    return invalidEmails;
  }
}

App.showMask = function(el) {
  $("#spinner").show();
}

App.hideMask = function() {
  if (!App.maskTimeout) {
    $("#spinner").hide();
  } else {
    clearTimeout(App.maskTimeout);
  }

  App.maskTimeout = setTimeout(function () {
    App.maskTimeout = null;
    $("#spinner").hide();
  }, 500);
}

var Helpers = {
  timeOrTimeAgo: function(str){
    var time = moment(str),
      timeStr = time.format("MMMM Do YYYY, h:mm a");

    if((moment().diff(time, 'day') >= 2)){
      return '<span>'+ timeStr +'</span>';

    } else {
      return '<span title="'+ timeStr +'">'+ time.fromNow() +'</span>';
    }
  },
  prettyDuration: function(secs) {
    var hr = Math.floor(secs / 3600);
    var min = Math.floor((secs - (hr * 3600))/60);
    var sec = secs - (hr * 3600) - (min * 60);

    while (min.length < 2) {min = '0' + min;}
    while (sec.length < 2) {sec = '0' + min;}
    if (hr) hr += ':';
    return hr + min + ':' + sec;
  },

  truncate: function(str, length) {
    if(str && str.length > length){
      return $.trim(str).substring(0, length).split(" ").slice(0, -1).join(" ") + "...";
    } else {
      return str;
    }
  },

  sanitize: function(str){
    App.vars.tempDiv.html(str);
    App.vars.tempDiv.find('style, script, link').remove();
    return App.vars.tempDiv.html();
  },

  formatMarketingNote: function(note) {
    return note ? note.replace("</b>", "</b><p>")  + "</p>" : "";
  },

  isSelected: function (val1, val2) {
    return val1 == val2 ? "selected" : ""
  },

  isChecked: function (val1, val2) {
    if( _.isArray(val1) ){
      return _.contains(val1, val2) ? "checked" : "";

    } else {
      return val1 == val2 ? "checked" : "";

    }
  },

  nFormatter: function (num) {
    if (num >= 1000000000) {
      return (num / 1000000000).toFixed(1) + 'G';
    }
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M';
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'K';
    }
    return num;
  },

  lineBreakAndLink: function (text) {
    return text.replace(/[\r\n]{1}/g, " <br/> ").replace(/href=/g, "target='_blank' href=")
      .replace(/(http?:\/\/\S*)/g, '<a href="$1" target="_blank">$1</a>');
  },

  editProfile: function(id){
    return App.vars.userId == id;
  },
  
  escapeEmail: function(e){
    return e.replace(/</g, "&lt;").replace(/>/g, "&gt;")
  },

  activityIcon: function(action) {
    var cls = "";

    switch( action ){
      case "send_mail":
        cls = "fa fa-envelope";
        break;

      case "open_mail":
        cls = "fa fa-envelope-o";
        break;

      case "click_link":
        cls = "fa fa-link";
        break;

      case "schedule":
        cls = "fa fa-clock-o";
        break;

      case "import":
        cls = "fa fa-plus";
        break;

      case "download":
        cls = "fa fa-download";
        break;

      case "win":
        cls = "fa fa-trophy";
        break;

      case "enter":
        cls = "fa fa-sign-in";
        break;

      case "subscribe":
      case "subscribe_page":
      case "bulk_unsubscribe":
        cls = "fa fa-frown-o";
        break;

      case "unsubscribe":
      case "unsubscribe_confirm":
      case "unsubscribe_confirm_all":
      case "unsubscribe_blacklisted":
      case "unsubscribe_bounce":
      case "unsubscribe_complaint":
      case "bulk_resubscribe":
        cls = "fa fa-frown-o";
        break;

      case "refer":
      case "referred_by":
        cls = "fa fa-users";
        break;

      case "bad_email_verified":
      case "bad_email_found":
        cls = "fa fa-frown-o";
        break;

      case "bounce":
        cls = "fa fa-arrow-left";
        break;

      case "blacklist":
      case "complain":
        cls = "fa fa-exclamation-triangle";
        break;
    }

    return cls;
  }

} // /Helpers

//global functions

function msgbox(msg, type){
  $('#notify').notify({
    type: type || "success",
    message: { html: msg }
  }).show();
};
String.prototype.trunc = String.prototype.trunc ||
  function(n){
      return this.length>n ? this.substr(0,n-1)+'&hellip;' : this;
};

var ClickableRow = Backgrid.Row.extend({
  events: {
    "click": "onClick"
  },
  onClick: function () {
    Backbone.trigger("rowclicked", this.model);
  }
});
