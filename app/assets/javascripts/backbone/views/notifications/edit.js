Crm.Views.NotificationEdit = Crm.Views.NotificationNewOrUpdate.extend({
	isCreateNew: false,
	className: 'create-update', //append to layout
	

	_delete: function(evt){
	  var self = this;
	  
	  bootbox.confirm("Sure you want to delete this notification? There is no undo.", function(result) {
      if (result) {
        self.collection.remove(self.model);
      }
    });

	  evt.stopPropagation();

	  return false;
	}
});