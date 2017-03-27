module FSM
  module WordPress
    module Command
      
      # Return the first OpsWorks command's data bag
      def self.info
        @info ||= Chef::Search::Query.new.search(:aws_opsworks_command).first
      end
      
      def self.timestamp
        @timestamp ||= self.info&.dig(:sent_at)&.delete("^0-9")
      end
      
    end
  end
end
