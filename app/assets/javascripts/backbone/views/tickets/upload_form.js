Crm.Views.TicketUploadForm = Backbone.View.extend({
  id: 'upload-wrap',
  template: JST['backbone/templates/tickets/upload_form'],
  events:	{
		"click .upload": "upload"
	},
	
  upload: function(){
    if( !this.uploading ) {
      if(this.$('#file-import:visible')[0]){
        this.$('#file-import').submit();

      } else {
        this.$('.upload-local-files').click();
      }
    }
  },

  render: function () {
    this.$el.html(this.template());
    this.setupUpload();
    return this;
  },
  
  setupUpload: function(){
    var self = this,
      uploadWrap = self.$el,
      dropZone = uploadWrap.find('.drop-zone'),
      dropZoneTimeout = null,
      fileUpload = uploadWrap.find('#file-upload'),
      uploadList = uploadWrap.find('#upload-list'),
      fileImport = uploadWrap.find('#file-import');
      
    //interactions
    uploadWrap.on('click', '.dropbox', function(){//https://www.dropbox.com/developers/dropins/chooser/js
      Dropbox.choose({
          linkType: "direct",
          multiselect: true,
          success: function(files) {            
            uploadWrap.find("#import-dropbox .table").append( tmpl("template-dropbox-files", {files: files, fileSize: prettyFileSize}) );
            fileImport.show();
            uploadList.hide();
            fileImport.find('a[href=#import-dropbox]').click();
          },
          cancel: function() {}
      });
      return false;

    }).on('click', '.ggdrive', function(){
      ggPicker.open();
      return false;

    });

    //init form
   fileUpload.fileupload({
      url: App.vars.assetsPath,
      disableImageResize: /Android(?!.*Chrome)|Opera/.test(window.navigator.userAgent),
      maxFileSize: 10000000,
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png|ico|pdf|doc|docx|xls|xlsx|ppt|pptx|txt)$/i,
      dropZone: dropZone,
      previewMaxWidth: 60,
      previewMaxHeight: 60
      
    }).on('fileuploadadded', function (e, data) {
      fileImport.hide();
      uploadList.show();
      
    }).on('fileuploadstart', function (e, data) {
      self.ticketFormView.$el.mask('Please wait...');
      self.uploading = true;
      
    }).on('fileuploadstop', function (e, data) {
      setTimeout(function(){
        var ids = [];
        uploadWrap.find('.template-download').each(function(){
          ids.push( $(this).attr('data-id') );
        });

        if(ids.length > 0) {
          uploadList.hide().find('.files').empty();
          self.ticketFormView.$('#asset-ids').val( ids.join(",") );
          self.ticketFormView.createOrUpdate();
          
        } else {
          msgbox("There was an error, please try again!", "danger");
        }

        self.uploading = false;
      }, 200);
    })
    
    fileImport.on('click', '.table .remove', function(){
      $(this).closest('tr').remove();
      return false;
      
    }).on('click', '.cancel', function(){
      fileImport.hide();
      return false;
      
    });
    
    fileImport.ajaxForm({
      dataType: 'json',
      beforeSerialize: function(){
        var source = fileImport.find('.tab-pane:visible').attr('data-source');
        
        if(source == "dropbox" || source == "ggdrive"){
          if(fileImport.find('tr').length == 0){
            return false;
          }
        }
        
        fileImport.find('input[name=target]').val(App.vars.uploadTarget);
        fileImport.find('input[name=source]').val(source);

        if(source == "ggdrive"){
          fileImport.find('input[name=access_token]').val(gapi.auth.getToken().access_token);
        }
        
        self.uploading = true;
        self.ticketFormView.$el.mask("Please wait...");
      },
      success: function(data){
        var ids = _.map(data.files, function(a){ return a.id; });

        if(ids.length > 0) {
          fileImport.find('.table').empty();
          fileImport.hide();
          self.ticketFormView.$('#asset-ids').val( ids.join(",") );
          self.ticketFormView.createOrUpdate();
          
        } else {
          msgbox("There was an error, please try again!", "danger");
        }
        
        self.uploading = false;
      }
    });
    
    //drag drop effect
    $(document).bind('dragover', function (e) {
      var found = false,
        node = e.target;
        
      if (!dropZoneTimeout) {
        dropZone.addClass('in');
      } else {
        clearTimeout(dropZoneTimeout);
      }
        
      do {
        if (node === dropZone[0]) {
       		found = true;
       		break;
       	}
       	node = node.parentNode;
      } while (node != null);
      
      if (found) {
        dropZone.addClass('hover');
      } else {
        dropZone.removeClass('hover');
      }
      
      dropZoneTimeout = setTimeout(function () {
        dropZoneTimeout = null;
        dropZone.removeClass('in hover');
      }, 100);
    });
    
    Crm.viewInst.currUpload = this; //only used in google drive callback, don't use this variable to traverse DOM
  }
});