module FSM
  module WordPress
    module App

      # Find and return the correct app data bag being deployed
      def self.info
        @info ||= Chef::Search::Query.new.search(:aws_opsworks_app).find do |app|
          # HACK: Need to change staging environment app shortname to match others (fsm_wordpress)
          # app[:deploy] and app[:shortname] == 'fsm_wordpress'
          app[:deploy] and %w(fsm_wp_env fsm_wordpress).include? app[:shortname]
        end
      end
      
      # Get the correct data source information from the app
      def self.data_source
        @data_source ||= self.info[:data_sources]&.find do |src|
          (src[:type] == 'RdsDbInstance') and (src[:name].end_with? '_env')
        end
      end
      
      # Rub a block of code when the app is being deployed
      def self.on_deploy
        app = self.info
        yield app if app
      end
      
    end
  end
end
