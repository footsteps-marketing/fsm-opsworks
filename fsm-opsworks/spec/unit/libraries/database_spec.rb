require 'unit_helper'

require 'database'

describe FSM::WordPress::Database do
  app_data_source = {
    name:          'foo_env',
    database_name: 'NAME',
    type:          'RdsDbInstance',
    arn:           'correct_arn'
  }
  correct_database = {
    rds_db_instance_arn: 'correct_arn',
    db_user:             'USER',
    db_password:         'PASS',
    address:             'HOST'
  }
  incorrect_database = { rds_db_instance_arn: 'incorrect_arn' }
  
  let(:database) { FSM::WordPress::Database.clone }
  
  describe '.info' do
    context 'when OpsWorks has an RDS instance matching the app\'s correctly configured data source' do
      it 'returns the correct RDS DB data bag' do
        stub_search_result(:aws_opsworks_rds_db_instance, [ incorrect_database, correct_database ])
        expect(FSM::WordPress::App).to receive(:data_source).and_return app_data_source
        expect(database.info).to be correct_database
      end
    end
  
    context 'when the app has no correctly configured RDS database' do
      it 'returns nil' do
        stub_search_result(:aws_opsworks_rds_db_instance, [ incorrect_database, correct_database ])
        expect(FSM::WordPress::App).to receive(:data_source).and_return nil
        expect(database.info).to be_nil
      end
    end
    
    context 'when OpsWorks does not have the correct RDS instance' do
      it 'returns nil' do
        stub_search_result(:aws_opsworks_rds_db_instance, [ incorrect_database ])
        expect(FSM::WordPress::App).to receive(:data_source).and_return app_data_source
        expect(database.info).to be_nil
      end
    end
  end
  
  describe '.creds' do
    context 'when the database info' do
      context 'can be retrieved' do
        it 'returns the database credentials' do
          expect(FSM::WordPress::App).to receive(:data_source).and_return app_data_source
          expect(database).to receive(:info).and_return correct_database
          expect(database.creds).to match({
            database: 'NAME',
            user:     'USER',
            password: 'PASS',
            host:     'HOST' 
          })
        end
      end
      
      context 'can\'t be retrieved' do
        it 'returns nil' do
          expect(database).to receive(:info).and_return nil
          expect(database.creds).to be_nil
        end
      end
    end
  end
end