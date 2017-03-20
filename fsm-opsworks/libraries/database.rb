module FSM::WordPress::Database
  
  # Find and return the correct RDS instance data bag for the app
  def self.info
    @info ||= Chef::Search::Query.new.search(:aws_opsworks_rds_db_instance).find do |db|
      db[:rds_db_instance_arn] == App.data_source[:arn]
    end
  end
  
  # Get the database credentials
  def self.creds
    @creds ||= {
      database: App.data_source[:database_name],
      user:     self.info[:db_user],
      password: self.info[:db_password],
      host:     self.info[:address]
    }
  end
  
end
