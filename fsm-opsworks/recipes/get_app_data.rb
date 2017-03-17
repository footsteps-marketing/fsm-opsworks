log 'getting_app_data' do
  message 'Getting application data'
  level :debug
end

search("aws_opsworks_app").each do |app|
  # Find the correct app data bag being deployed
  # HACK: Need to change staging environment app shortname to match others (fsm_wordpress)
  # next unless (app[:shortname] == 'fsm_wordpress') and app[:deploy]
  next unless %w(fsm_wp_env fsm_wordpress).include?(app[:shortname]) and app[:deploy]
  
  Chef::Log.debug("Getting database credentials for #{app[:name]} app deployment")
  
  db_arn = app[:data_sources]
  
  node[:wordpress][:database][:user]
end