namespace :rubber do

  namespace :ci do
  
    rubber.allow_optional_tasks(self)
    
    before "deploy:update_code", "rubber:ci:create_directories"

    task :create_directories, :roles => [:app, :db] do
      rubber.sudo_script 'create_directories', <<-ENDSCRIPT
        if [[ ! -d /mnt/#{rubber_env.app_name}-#{Rubber.env}/ ]]; then
          mkdir -p /mnt/#{rubber_env.app_name}-#{Rubber.env}/releases
          mkdir -p /mnt/#{rubber_env.app_name}-#{Rubber.env}/shared/log
        fi
      ENDSCRIPT
    end
    
    
  end
end
