require 'unit_helper'

require 'app'

describe FSM::WordPress::App do
  correct_data_source   = { name: 'foo_env', type: 'RdsDbInstance' }
  incorrect_data_source = { name: 'another', type: 'RdsDbInstance' }
  correct_app   = { shortname: 'fsm_wordpress', deploy: true }
  incorrect_app = { shortname: 'incorrect_app', deploy: true }
  nodeploy_app  = { shortname: 'fsm_wordpress', deploy: false }
  
  def stub_search_result(result)
    query = instance_double("Chef::Search::Query")
    expect(query).to receive(:search).with(:aws_opsworks_app)
      .and_return(result)
      
    query_class = class_double("Chef::Search::Query")
      .as_stubbed_const(:transfer_nested_constants => true)
    expect(query_class).to receive(:new).and_return(query)
  end
  
  let(:app) { FSM::WordPress::App.clone }
  
  describe '.info' do
    context 'when the fsm_wordpress app exists in the OpsWorks stack' do
      
      context 'and the app is being deployed' do
        it 'returns the correct app data bag' do
          stub_search_result([ incorrect_app, correct_app, incorrect_app ])
          expect(app.info()).to match correct_app
        end
      end
      
      context 'but the app is not being deployed' do
        it 'returns nil' do
          stub_search_result([ incorrect_app, nodeploy_app, incorrect_app ])
          expect(app.info()).to be_nil
        end
      end
    end
    
    context 'when the stack has no fsm_wordpress app' do
      it 'returns nil' do
        stub_search_result([ incorrect_app, incorrect_app ])
        expect(app.info()).to be_nil
      end
    end
  end
  
  describe '.data_source' do
    context 'when a *_env RDS database is configured on the OpsWorks app' do
      it 'returns the correct database info' do
        expect(app).to receive(:info).and_return(correct_app.merge({
          data_sources: [ incorrect_data_source, correct_data_source ]
        }))
        expect(app.data_source).to match correct_data_source
      end
    end
  end
    
end
