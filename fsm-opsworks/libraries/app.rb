module App
  def self.data
    return @data if defined? @data
    
    Chef::Search::Query.new.search("aws_opsworks_app").each do |app|
      # Find the correct app data bag being deployed
      # HACK: Need to change staging environment app shortname to match others (fsm_wordpress)
      # next unless app[:deploy] and app[:shortname] == 'fsm_wordpress'
      next unless app[:deploy] and %w(fsm_wp_env fsm_wordpress).include? app[:shortname]
      
      @data = app
    end
    
    return @data
  end
end