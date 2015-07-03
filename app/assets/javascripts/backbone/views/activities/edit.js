Crm.Views.ActivityEdit = Crm.Views.ActivityNewOrUpdate.extend({
	isCreateNew: false,
  className: 'create-update',
	

	_delete: function(evt){
	  var self = this;
	  
	  bootbox.confirm("Sure you want to delete this activity? There is no undo.", function(result) {
      if (result) {
        self.collection.remove(self.model);
      }
    });

	  evt.stopPropagation();

	  return false;
	}
});