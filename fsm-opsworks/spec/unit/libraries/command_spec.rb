require 'unit_helper'

require 'command'

describe FSM::WordPress::Command do
  correct_command = { sent_at: '2017-03-27T23:06:52+00:00' }
  other_command =   { sent_at: '2017-03-27T23:10:00+00:00' }
  
  let(:command) { FSM::WordPress::Command.clone }
  
  describe '.info' do
    it 'returns the information of the first command found' do
      stub_search_result(:aws_opsworks_command, [ correct_command, other_command ])
      expect(command.info).to match correct_command
    end
  end
  
  describe '.timestamp' do
    it 'returns the command sent timestamp as a string containing only digits' do
      expect(command).to receive(:info).and_return correct_command
      expect(command.timestamp).to eq('201703272306520000')
    end
  end
end
