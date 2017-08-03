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

/**
 * Aplication start
 */
App.init = function() {
  App.Debug.log("App - Init");
  App.Debug.init();
  App.UI.init();
};

/**
 * App the config details
 */

App.Config = {
    APP_VERSION: "1.0",
    APP_CODE: "APP",
    APP_LOCALE: 'en/US',
    DEBUG_MODE: 0, // 1:ON, 0:OFF
    BASE_URL: "/",
    LOGIN_URL: "/login",
    ATTACHMENT_SIZE_LIMIT: 10, // in MB
    ATTACHMENT_TIMEOUT: 4 * 60, // in seconds
    FOO: 0
};

/**
 * Some utility functions
 */
App.Utils = {
    getUrlParam: function(paramName) {
        var str = window.location.search;
        var result = {};
        str.replace(/([^?=&]+)(?:[&#]|=([^&#]*))/g, function(match, key, value) {
                if (key.indexOf("[]") !== -1) {
                    key = key.replace(/\[\]$/, "");
                    if (!(result[key])) {
                        result[key] = new Array();
                    }
                    result[key].push(value);
                } else {
                    result[key] = value || 1;
                }
            });
        if (result[paramName]) {
            return result[paramName];
        } else {
            return '';
        }
    },
    getSearchParam: function(searchString, paramName) {
        var result = {};
        searchString.replace(/([^?=&]+)(?:[&#]|=([^&#]*))/g, function(match, key, value) {
                if (key.indexOf("[]") !== -1) {
                    key = key.replace(/\[\]$/, "");
                    if (!(result[key])) {
                        result[key] = new Array();
                    }
                    result[key].push(value);
                } else {
                    result[key] = value || 1;
                }
            });
        if (result[paramName]) {
            return result[paramName];
        } else {
            return '';
        }
    },
    geoProximity: function(lat1, lon1, lat2, lon2) {
        var radlat1 = Math.PI * lat1 / 180;
        var radlat2 = Math.PI * lat2 / 180;
        var radlon1 = Math.PI * lon1 / 180;
        var radlon2 = Math.PI * lon2 / 180;
        var theta = lon1 - lon2;
        var radtheta = Math.PI * theta / 180;
        var distance = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
        distance = Math.acos(distance);
        distance = distance * 180 / Math.PI;
        distance = distance * 60 * 1.1515;
        distance = MH.Utils.roundFloat(distance, 1);
        return distance + " mi";
    },
    fuzzyTime: function(datetimestamp) {
        var datetimestampParts = datetimestamp.split(" ");
        var dateParts = datetimestampParts[0].split("-");
        var pastDate = new Date(dateParts[1] + "/" + dateParts[2] + "/" + dateParts[0] + " " + datetimestampParts[1] + " UTC");
        var seconds = Math.floor((new Date() - pastDate) / 1000);
        var interval = Math.floor(seconds / 31536000);
        if (interval > 1) {
            return interval + " years";
        }
        interval = Math.floor(seconds / 2592000);
        if (interval > 1) {
            return interval + " months";
        }
        interval = Math.floor(seconds / 86400);
        if (interval > 1) {
            return interval + " days";
        }
        interval = Math.floor(seconds / 3600);
        if (interval > 1) {
            return interval + " hours";
        }
        interval = Math.floor(seconds / 60);
        if (interval > 1) {
            return interval + " minutes";
        }
        return Math.floor(seconds) + " seconds";
    },
    formatTimestamp: function(tsString, utcTime) {
        if (utcTime) {
            var utcDateString = moment(tsString).format('MM/DD/YYYY hh:mm:ss A UTC');
            var localDate = new Date(utcDateString);
            return moment(localDate.toString()).format('MMM Do, hh:mm A');
        } else {
            return moment(tsString).format('MM/DD/YY');
        }
    },
    smartTrim: function(string, length) {
        return string.length > length ? string.substr(0, length - 1) + '&hellip;' : string;
    },
    roundFloat: function(value, decimals) {
        decimals = (decimals) ? decimals : 2;
        return parseFloat(value, 10).toFixed(decimals);
        //Math.round(value*100)/100;
    },
    htmlFix: function(value) {
        return $('<div/>').html(value).html();
    },
    htmlEncode: function(s) {
        var el = document.createElement("div");
        el.innerText = el.textContent = s;
        s = el.innerHTML;
        return s;
    },
    htmlEscape: function htmlEscape(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    },
    cmToAlt: function(cm) {
        var feets = cm * 0.3937008 / 12;
        return Math.floor(feets) + "'" + Math.floor((feets - Math.floor(feets)) * 12) + "''";
    },
    nl2br: function(str) {
        return str.replace(/\n/g, "<br />");
    },
    newLineToBr: function(str) {
        return str.replace(/\\n/g, "<br />");
    },
    isValidEmail: function(email) {
        var pattern = /^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/;
        return email.match(pattern);
    },
    isValidZipCode: function(zipCode) {
        var zipCodePattern = /^\d{5}$|^\d{5}$|^\d{5}-\d{4}$/;
        return zipCodePattern.test(zipCode);
    },
    isValidUrl: function(url) {
        var regexPattern = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
        return regexPattern.test(url);
    },
    isValidDate: function(s) {
        // Expect input as YYYY-mm-dd
        var bits = s.split('-');
        var d = new Date(bits[0], bits[1] - 1, bits[2]);
        return d && (d.getMonth() + 1) == bits[1] && d.getDate() == Number(bits[2]);
    },
    isValidRealNumber: function(s) {
        var regExp = /^-?\d+\.?\d*$/;
        return s.match(regExp);
    },
    isRealNumber: function(s) {
        var regExp = /([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+)|([0-9]+)/;
        return s.match(regExp);
    },
    isImage: function(mimeType) {
        var regExp = new RegExp("image", "i");
        return mimeType.match(regExp);
    },
    isAudio: function(mimeType) {
        var regExp = new RegExp("audio", "i");
        return mimeType.match(regExp);
    },
    isVideo: function(mimeType) {
        var regExp = new RegExp("video", "i");
        return mimeType.match(regExp);
    },
    isValidPassword: function(str) {
        var validated = true;
        if (str.length < 6) {
            validated = false;
        }
        if (!/\d/.test(str)) {
            validated = false;
        }
        if (!/[a-z]/.test(str)) {
            validated = false;
        }
        if (!/[A-Z]/.test(str)) {
            validated = false;
        }
        return validated;
    },
    pad: function(str, max) {
        return str.length < max ? MH.Utils.pad("0" + str, max) : str;
    },
    isHandHeld: function() {
        return (/android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(navigator.userAgent.toLowerCase()));
    },
    addHtmlClasses: function() {
        MH.Utils.addBrowserSpecificClasses();
        $('body').removeClass('landscape');
        $('body').removeClass('portrait');
        if (MH.Utils.isLandscapeMode()) {
            $('body').addClass('landscape');
        } else {
            $('body').addClass('portrait');
        }
    },
    addBrowserSpecificClasses: function() {
        if (MH.Utils.isIEMobile()) {
            $('body').addClass('iemobile');
        }
        if (MH.Utils.isIEMobile(8)) {
            $('body').addClass('iemobile8');
        }
        if (MH.Utils.isIEMobile(9)) {
            $('body').addClass('iemobile9');
        }
        if (MH.Utils.isIEMobile(10)) {
            $('body').addClass('iemobile10');
        }
        if (MH.Utils.isIEMobile(11)) {
            $('body').addClass('iemobile11');
        }
        if (MH.Utils.isiOSSafari()) {
            $('body').addClass('iossafari');
        }
        if (MH.Utils.isDroidBrowser()) {
            $('body').addClass('droid');
        }
        if (MH.Utils.isBB10()) {
            $('body').addClass('blackberry');
        }
    },
    getiOSversion: function() {
        if (/iP(hone|od|ad)/.test(navigator.platform)) {
            // supports iOS 2.0 and later: <http://bit.ly/TJjs1V>
            var v = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/);
            return [parseInt(v[1], 10), parseInt(v[2], 10), parseInt(v[3] || 0, 10)];
        }
    },
    isiOS6Safari: function() {
        return (navigator.userAgent.match(/OS 6(_\d)+ like Mac OS X/i));
    },
    isiOSSafari: function(osVersion) {
        var regExp = new RegExp("like Mac OS X", "i");
        if (osVersion) {
            regExp = new RegExp('OS ' + osVersion + '(_\\d)+ like Mac OS X', "i");
        }
        return (navigator.userAgent.match(regExp));
    },
    isiOSChrome: function(osVersion) {
        var regExp = new RegExp("CriOS", "i");
        return (navigator.userAgent.match(regExp));
    },
    isiPhone: function() {
        return (navigator.userAgent.match(/iPhone/i));
    },
    isiPad: function() {
        return (navigator.userAgent.match(/iPad/i));
    },
    isDroidBrowser: function() {
        //var regExp = new RegExp("android", "i");
        var regExp = new RegExp("droid", "i");
        return (navigator.userAgent.match(regExp));
    },
    isIEFamily: function() {
        return MH.Utils.isIE() || MH.Utils.isIEMobile() || MH.Utils.isIETrident() || MH.Utils.isIEEdge();
    },
    isIE: function(ieVersion) {
        var regExp = new RegExp("MSIE", "i");
        if (ieVersion) {
            regExp = new RegExp('MSIE ' + ieVersion + '.(\\d)+', "i");
        }
        return (navigator.userAgent.match(regExp));
    },
    isIEMobile: function(ieVersion) {
        var regExp = new RegExp("IEMobile", "i");
        if (ieVersion) {
            regExp = new RegExp('IEMobile\/' + ieVersion + '.(\\d)+', "i");
        }
        return (navigator.userAgent.match(regExp));
    },
    isIETrident: function(ieVersion) {
        var regExp = new RegExp("Trident", "i");
        if (ieVersion) {
            regExp = new RegExp('Trident\/' + ieVersion + '.(\\d)+', "i");
        }
        return (navigator.userAgent.match(regExp));
    },
    isIEEdge: function(ieVersion) {
        var regExp = new RegExp("Edge", "i");
        if (ieVersion) {
            regExp = new RegExp('Edge\/' + ieVersion + '.(\\d)+', "i");
        }
        return (navigator.userAgent.match(regExp));
    },
    isBlackberry: function() {
        var regExp = new RegExp("BlackBerry", "i");
        return (navigator.userAgent.match(regExp));
    },
    isBB10: function() {
        var regExp = new RegExp("BB10", "i");
        return (navigator.userAgent.match(regExp));
    },
    isWebkit: function() {
        var regExp = new RegExp("webkit", "i");
        return (navigator.userAgent.match(regExp));
    },
    isLandscapeMode: function() {
        if (window.orientation && (window.orientation == 90 || window.orientation == -90)) {
            return true;
        }
        return false;
    },
    setCookie: function(key, value) {
        var expires = new Date();
        expires.setTime(expires.getTime() + 2592000000);
        document.cookie = key + '=' + value + ';path=/;expires=' + expires.toUTCString();
    },
    setSessionCookie: function(key, value) {
        if (MH.Utils.isIEFamily()) {
            document.cookie = key + '=' + value + ';path=/';
        } else {
            document.cookie = key + '=' + value + ';expires=0;path=/';
        }
    },
    delCookie: function(key) {
        document.cookie = key + '=;path=/;expires=Thu, 01 Jan 1970 00:00:01 MHT;';
    },
    getCookie: function(key) {
        var keyValue = document.cookie.match('(^|;) ?' + key + '=([^;]*)(;|$)');
        return keyValue ? keyValue[2] : null;
    },
    pregQuote: function(str) {
        return (str + '').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
    },
    highlight: function(data, search) {
        return data.replace(new RegExp("(" + MH.Utils.pregQuote(search) + ")", 'gi'), "<b>$1</b>");
    },
    getCaret: function(el) {
        if (el.selectionStart) {
            return el.selectionStart;
        } else if (document.selection) {
            el.focus();
            var r = document.selection.createRange();
            if (r == null) {
                return 0;
            }
            var re = el.createTextRange(),
                rc = re.duplicate();
            re.moveToBookmark(r.getBookmark());
            rc.setEndPoint('EndToStart', re);
            return rc.text.length;
        }
        return 0;
    },
    generateUUID: function() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                var r = Math.random() * 16 | 0,
                    v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
    },
    humanFileSize: function(bytes, si) {
        var thresh = si ? 1000 : 1024;
        if (bytes < thresh) return bytes + ' B';
        var units = si ? ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'] : ['KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
        var u = -1;
        do {
            bytes /= thresh;
            ++u;
        } while (bytes >= thresh);
        return bytes.toFixed(1) + ' ' + units[u];
    },
    formatNumberInside: function(str) {
        var parts = str.split('$');
        if (parts.length > 1) {
            parts[1] = MH.Utils.convertToFormattedNumber(parts[1]);
        }
        return parts.join('$ ');
    },
    isElementVisible: function(elementToBeChecked) {
        var TopView = $(window).scrollTop();
        var BotView = TopView + $(window).height();
        var TopElement = $(elementToBeChecked).offset().top;
        var BotElement = TopElement + $(elementToBeChecked).height();
        return ((BotElement <= BotView) && (TopElement >= TopView));
    },
    getImageOriginalDimensions: function(imgElement) {
        var img = new Image();
        img.src = (imgElement.attr ? imgElement.attr("src") : false) || imgElement.src;
        return img;
    }
};

/**
 * Debug Application
 */
App.Debug = {
    init: function() {
      App.Debug.log("Debug - Init");
        if (App.Config.DEBUG_JS) {
            App.Config.DEBUG_MODE = 1;
        }
        if (App.Utils.getUrlParam('debugjs')) {
            App.Config.DEBUG_MODE = 1;
        }
        if (App.Config.DEBUG_MODE) {
            App.Debug.log("Debug mode is ON");
        } else {
            App.Debug.log("Debug mode is OFF");
        }
    },
    enable: function() {
        App.Config.DEBUG_MODE = 1;
        App.Debug.log("Debug mode enabled");
    },
    disable: function() {
        App.Debug.log("Debug mode disabled");
        App.Config.DEBUG_MODE = 0;
    },
    error: function(debugVar) {
        App.Debug.log(debugVar, 'error');
    },
    info: function(debugVar) {
        App.Debug.log(debugVar, 'info');
    },
    debug: function(debugVar) {
        App.Debug.log(debugVar, 'debug');
    },
    log: function(debugVar, type) {
        if (App.Config.DEBUG_MODE) {
            if (typeof console != 'undefined' && console) {
                if (type && console[type]) {
                    console[type](debugVar);
                } else {
                    console.log(debugVar);
                }
            }
        }
    },
    rest: function(url, method, headers, params, dataType) {
        $.ajax({
                url: url,
                type: method,
                //  dataType : "json",
                cache: false,
                headers: headers,
                data: params,
                success: function(data, textStatus, jqXHR) {
                    App.Debug.log(jqXHR);
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    App.Debug.log(jqXHR);
                }
            });
    }
};

/**
 * Debug Application
 */
App.UI = {
    init: function() {
        App.Debug.log("UI - Init");
        App.UI.interceptAjax();
    },
    interceptAjax: function() {
      App.Debug.log("UI - Setup Ajax intercept");
      jQuery.ajaxSetup({
        dataFilter: function (data, type) {
          if (type == 'json' && data) {
            var jSONData = JSON.parse(data);
            if (jSONData && jSONData.status && jSONData.status.code == 401) {
              window.location.href = App.Config.LOGIN_URL;
            }
          }
          return data;
        }
      });
    }
}

// Shorthand for $( document ).ready()
$(function() {
  App.init();
});