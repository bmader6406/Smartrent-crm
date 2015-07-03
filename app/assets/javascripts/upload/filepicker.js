(function() {
	/**
	 * Initialise a Google Driver file picker
	 */
	var FilePicker = window.FilePicker = function(options) {
		// Config
		this.apiKey = options.apiKey;
		this.clientId = options.clientId;
		
		// Events
		this.onSelect = options.onSelect;
		this.onCancel = options.onCancel;
		
		// Load the drive API
		gapi.client.setApiKey(this.apiKey);
		gapi.client.load('drive', 'v2', this._driveApiLoaded.bind(this));
		google.load('picker', '1', { callback: this._pickerApiLoaded.bind(this) });
	}

	FilePicker.prototype = {
		/**
		 * Open the file picker.
		 */
		open: function() {		
			// Check if the user has already authenticated
			var token = gapi.auth.getToken();
			if (token) {
				this._showPicker();
			} else {
				// The user has not yet authenticated with Google
				// We need to do the authentication before displaying the Drive picker.
				this._doAuth(false, function() { this._showPicker(); }.bind(this));
			}
		},
		
		/**
		 * Show the file picker once authentication has been done.
		 * @private
		 */
		_showPicker: function() {
		  if(this.picker){
		    this.picker.setVisible(true);
		    
		  } else {
		    var accessToken = gapi.auth.getToken().access_token,
		      view = new google.picker.View(google.picker.ViewId.DOCS);
		      
        view.setMimeTypes("image/png,image/jpeg,image/jpg,image/gif");

        this.picker = new google.picker.PickerBuilder()
          .enableFeature(google.picker.Feature.NAV_HIDDEN)
          .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
          .disableFeature(google.picker.Feature.SIMPLE_UPLOAD_ENABLED)
          .enableFeature(google.picker.Feature.MINE_ONLY)  
          .setAppId(this.clientId)
          .setOAuthToken(accessToken)
          .addView(view)
          .setCallback(this._pickerCallback.bind(this))
          .build()
          .setVisible(true);
		  }
		},
		
		/**
		 * Called when a file has been selected in the Google Drive file picker.
		 * @private
		 */
		_pickerCallback: function(data) {
			if (data[google.picker.Response.ACTION] == google.picker.Action.PICKED) {
				var files = data[google.picker.Response.DOCUMENTS],
				  self = this;
				
				$.each(files, function(i, file){
				  var request = gapi.client.drive.files.get({
    					fileId: file[google.picker.Document.ID]
    				});

    			request.execute(self._fileGetCallback.bind(self));
				});
				
			}else if(data.action == google.picker.Action.CANCEL){
        if (this.onCancel) {
  				this.onCancel();
  			}
			}
		},
		/**
		 * Called when file details have been retrieved from Google Drive.
		 * @private
		 */
		_fileGetCallback: function(file) {
			if (this.onSelect) {
				this.onSelect(file);
			}
		},
		
		/**
		 * Called when the Google Drive file picker API has finished loading.
		 * @private
		 */
		_pickerApiLoaded: function() {
      
		},
		
		/**
		 * Called when the Google Drive API has finished loading.
		 * @private
		 */
		_driveApiLoaded: function() {
			this._doAuth(true);
		},
		
		/**
		 * Authenticate with Google Drive via the Google JavaScript API.
		 * @private
		 */
		_doAuth: function(immediate, callback) {	
			gapi.auth.authorize({
				client_id: this.clientId,
				scope: 'https://www.googleapis.com/auth/drive.readonly',
				immediate: immediate
			}, callback);
		}
	};
}());