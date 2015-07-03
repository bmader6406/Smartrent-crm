// App is defined in backbone-setup
// App functions can be overriden or resused in engines

App.initialize = function() {
  //app router
  var router = new App.Router(),
    self = this;

  $(document).on("click", "a[href^='/']", function(event){
    var link = $(event.currentTarget),
      href = link.attr('href'),
      target = link.attr('target'),
      sameProp = href.indexOf(App.vars.routeRoot) > -1,
      passThrough = href.indexOf('sign_out') > -1 || target // chain 'or's for other black list routes
    
    if( !link.parents('#viewport')[0] ){
      return true; // ignore link outside viewport
    }
    
    // Allow shift+click for new tabs, etc.
    if (sameProp && !passThrough && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey){
      // Remove leading slashes and hash bangs (backward compatablility)
      //var url = href.replace(/\/\d+\//, '').replace(/^\//,'').replace('\#\!\/','');
      
      var url = href.replace(/^\//,'').replace('\#\!\/',''); //routeRoot is /, need to remove the / of the target url

      // Instruct Backbone to trigger routing events
      router.navigate(url, true);
      
      return false
    }
  });
  
  //accounts
  App.collInst.users = new App.Collections.Users();

  router.on('route:showUsers', function() {
    if(!App.vars.ability.can("read", "User")){
      App.unauthorizedAlert();
      return false;
    }
    
    var userSearch = new App.Views.UserSearch(),
      usersList = new App.Views.UsersList({
        collection: App.collInst.users
      });

    $('#west').show().html(userSearch.render().$el);
    $('#center').attr('class', 'col-md-9').html(usersList.render().$el);
  });

  router.on('route:showUser', function(id) {
    if(!App.vars.ability.can("read", "User")){
      App.unauthorizedAlert();
      return false;
    }
    
    var user = App.collInst.users.get(id);

    if(!user && App.vars.userObj){
      user = new App.Models.User( App.vars.userObj );
      //manual set url if model not found in collection
      user.url = App.collInst.users.url + '/' + user.get('id');
    }

    if(user){
      var userInfo = new App.Views.UserInfo({
        model: user
      });

      $('#west').hide();
      $('#center').attr('class', 'col-md-12').html(userInfo.render().$el);

    } else {
      window.location.reload();
    }
  });

  router.on('route:newUser', function() {
    if(!App.vars.ability.can("cud", "User")){
      App.unauthorizedAlert();
      return false;
    }
    
    var usersList = new App.Views.UsersList({
        collection: App.collInst.users
      });

    $('#west').hide();
    $('#center').attr('class', 'col-md-12').html(usersList.render().$el);

    new App.Views.UserNew({
      collection: App.collInst.users
    }).render();

  });

  router.on('route:editUser', function(id) {
    if(! (App.vars.ability.can("cud", "User") || Helpers.editProfile(id)) ){
      App.unauthorizedAlert();
      return false;
    }
    
    var user = App.collInst.users.get(id),
      editUserForm;

    if(!user && App.vars.userObj){
      user = new App.Models.User( App.vars.userObj );
      //manual set url if model not found in collection
      user.url = App.collInst.users.url + '/' + user.get('id');
    }
    
    if (user) {
      editUserForm = new App.Views.UserEdit({
        model: user
      });
      
      $('#west').hide();
      $('#center').attr('class', 'col-md-12').html(editUserForm.render().$el);
    } else {
      window.location.reload();
    }
    
  });
  
  //access later
  App.routerInst = router;
  
  // trigger route matching
  Backbone.history.start({pushState: true, root: App.vars.routeRoot + "/"});
}

App.unauthorizedAlert = function (){
  msgbox("You are not authorized to access this page", "danger");
  //window.location.href = App.vars.unauthorizedPath;
}

App.setupDropdownNav = function() {
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
  var propertyDd = $('#prop-dd-nav'),
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
  
  // if( propertyDd.find('.list-group-item').length == 1){ //LM or PM
  //   propertyDd.find('.list-filter, .fa-angle-down').hide();
  // }

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

//Backbone View Helpers
var Helpers = {
  timeOrTimeAgo: function(str){
    var time = moment(str),
      timeStr = time.format("MMM Do YYYY <br> h:mm a");
    
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
    if(str.length > length){
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
  }
  
} // /Helpers


function msgbox(msg, type){
  $('#notify').notify({
    type: type || "success",
    message: { html: msg }
  }).show();
};


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