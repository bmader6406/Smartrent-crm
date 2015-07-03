window.App = { 
  vars: {},
  Models: {},
  Collections: {},
  Views: {},
  viewInst: {},
  collInst: {}
};

/* alias away the sync method */
Backbone._sync = Backbone.sync;

/* define a new sync method */
Backbone.sync = function(method, model, options) {
	/* only need a token for non-get requests */
  // if (method == 'create' || method == 'update' || method == 'delete') {
  //  /* grab the token from the meta tag rails embeds */
  //  var auth_options = {};
  //  auth_options[$("meta[name='csrf-param']").attr('content')] = $("meta[name='csrf-token']").attr('content');
  //  /* set it as a model attribute without triggering events */
  //  model.set(auth_options, {silent: true});
  // }
  
  if (!options.noCSRF) {
    var beforeSend = options.beforeSend;

    // Set X-CSRF-Token HTTP header
    options.beforeSend = function(xhr) {
      var token = $('meta[name="csrf-token"]').attr('content');
      if (token) xhr.setRequestHeader('X-CSRF-Token', token);
      if (beforeSend) return beforeSend.apply(this, arguments);
    };
  }
	
 // Serialize data, optionally using paramRoot
  if (options.data == null && model && (method === 'create' || method === 'update' || method === 'patch')) {
    options.contentType = 'application/json';
    data = JSON.stringify(options.attrs || model.toJSON(options));
    if (model.paramRoot) {
      data = {};
      data[model.paramRoot] = model.toJSON(options);
    } else {
      data = model.toJSON();
    }
    options.data = JSON.stringify(data);
  }

	/* proxy the call to the old sync method */
	return Backbone._sync(method, model, options);
}