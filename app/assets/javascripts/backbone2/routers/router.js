App.Router = Backbone.Router.extend({
  routes: {
    '': 'home',
    'accounts(/)': 'showUsers',
    'accounts/new(/)': 'newUser',
    'accounts/:id/edit(/)': 'editUser',
    'accounts/:id(/)': 'showUser'
  }
});
