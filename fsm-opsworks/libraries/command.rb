module FSM
  module WordPress
    module Command
      
      # Return the first OpsWorks command's data bag
      def self.info
        @info ||= Chef::Search::Query.new.search(:aws_opsworks_command).first
      end
      
      # Return the command sent timestamp as a string with only digits
      def self.timestamp
        @timestamp ||= self.info&.dig(:sent_at)&.delete("^0-9")
      end
      
    end
  end
end
