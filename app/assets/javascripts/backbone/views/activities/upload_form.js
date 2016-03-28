Crm.Views.DocumentUploadForm = Backbone.View.extend({
  id: 'upload-wrap',
  template: JST['backbone/templates/activities/upload_form'],
  events:	{
		"click .upload": "upload",
		"click .cancel": "cancel"
	},
	
  cancel: function(){
    this.$el.slideUp();
    this.$('#message').val("");
    $('#toolbar .btn').removeClass('selected');
    
    return false;
  },
  
  upload: function(){
    if(this.$('#file-import:visible')[0]){
      this.$('#file-import').submit();
      
    } else {
      this.$('.upload-local-files').click();
    }
  },
  
  createComment: function () {
    var self = this,
      method = this.collection.create,
      params = { 
        comment: { 
          type: 'document',
          asset_ids: this.$('#asset-ids').val(),
          message: this.$('#message').val()
        }
      };

    method.call(this.model || this.collection, params, {
      wait: true,
      error: function (model, xhr) {
        var errors = $.parseJSON(xhr.responseText);
        msgbox('File was not uploaded! ' + errors.join(", "), 'danger');
      },
      success: function (model, response) {
        msgbox('File was uploaded successfully!');
        self.$('#message').val("");
        $('.no-histories').hide();
      }
    });
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
            self.$('.upload-buttons').show();
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
      self.$('.upload-buttons').show();
      
    }).on('fileuploadstart', function (e, data) {
      self.$el.mask('Please wait...');
      
    }).on('fileuploadstop', function (e, data) {
      
      setTimeout(function(){
        var ids = [];
        uploadWrap.find('.template-download').each(function(){
          ids.push( $(this).attr('data-id') );
        });
        if(ids.length > 0) {
          uploadList.hide().find('.files').empty();
          self.$('#asset-ids').val( ids.join(",") );
          self.$el.unmask();
          self.$('.upload-buttons').hide();
          self.createComment();
          
        } else {
          msgbox("There was an error, please try again!", "danger");
        }
        
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
        
        self.$el.mask("Please wait...");
      },
      success: function(data){
        var ids = _.map(data.files, function(a){ return a.id; });

        if(ids.length > 0) {
          fileImport.find('.table').empty();
          fileImport.hide();

          self.$('#asset-ids').val(ids.join(","));
          self.$el.unmask();
          self.$('.upload-buttons').hide();
          
          self.createComment();
        } else {
          msgbox("There was an error, please try again!", "danger");
        }
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
    
    Crm.viewInst.currUpload = this;
  }
});