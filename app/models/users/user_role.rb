class UserRole < ActiveRecord::Base
  # for role revoke
  self.table_name = 'users_roles'
end