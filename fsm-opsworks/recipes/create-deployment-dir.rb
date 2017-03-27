FSM::WordPress::App.on_deploy do |app|
  deployment = File.join(app.revision_dir, app.revision)
  
  directory deployment do
    owner app.user
    group app.group
    mode '0775'
    recursive true
    action :create
  end
end
