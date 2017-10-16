Crm.Models.Resident = Backbone.Model.extend({
  
  defaults: {
    unit: {
      
    }
  },
  
  initialize: function() { 	
   this.set('name',App.Utils.htmlDecode(this.get('name')));
   this.set('email',App.Utils.htmlDecode(this.get('email')));
   this.set('full_name',App.Utils.htmlDecode(this.get('full_name')));
   this.set('property_name',App.Utils.htmlDecode(this.get('property_name')));
 }
 
});
