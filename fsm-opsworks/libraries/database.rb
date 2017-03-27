module FSM::WordPress::Database
  
  # Find and return the correct RDS instance data bag for the app
  def self.info
    correct_arn = FSM::WordPress::App.data_source&.dig :arn
    
    @info ||= Chef::Search::Query.new.search(:aws_opsworks_rds_db_instance).find do |db|
      db[:rds_db_instance_arn] == correct_arn
    end
  end
  
  # Get the database credentials
  def self.creds
    db = self.info
    return unless db
    
    @creds ||= {
      database: FSM::WordPress::App.data_source[:database_name],
      user:     db[:db_user],
      password: db[:db_password],
      host:     db[:address]
    }
  end
  
end
