# require 'test/unit'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/map_validator/validator_functions'
require_relative '../lib/map_validator/notifications'

WebMock.disable_net_connect!

def row_id_response_success(doc_fields)
  {
    status: 200,
    body: {
      response: {
        docs: doc_fields
      }
    }.to_json,
    headers: {}
  }
end

def row_id_response_400
  { status: 400, body: "{}" }
end

describe MapValidator do
  include MapValidator::ValidatorFunctions
  before(:all) do
    @app_config = { solr_url: 'http://localhost' }
  end


  before(:each) do
    @notifications = MapValidator::Notifications.new
    @meta = { col: '10', row: 'Test' }
  end

  describe 'notifications' do
    it 'correctly constructs notifications' do
      expect { @notifications.add_notification('CATASTROPHIC_ERROR') }.to raise_error(RuntimeError, 'Invalid type.')
      expect { @notifications.add_notification(:ERROR) }.to_not raise_error(RuntimeError)
      @notifications.add_notification(:WARNING, 'There was a problem, but only a little one.', 'C17')
      expect(@notifications.notification_list[1].message).to eq 'There was a problem, but only a little one.'
      expect(@notifications.notification_list[1].source).to eq('C17')
      @notifications.add_notification(:WARNING, 'The was a noteworthy event, but not necessarily a dangerous one', 'C17');
      expect(@notifications.notification_list.count).to eq(3)
    end
  end

  describe 'is_not_nil' do
    it 'correctly validates' do
      is_not_nil(@notifications, @meta, 'test-value')
      expect(@notifications.notification_list.length).to eq(0)
      is_not_nil(@notifications, @meta, nil)
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Value was missing.')
    end
  end

  describe 'is_not_empty' do
    it 'correctly validates' do
      is_not_empty(@notifications, @meta, 'test-value')
      expect(@notifications.notification_list.length).to eq(0)
      is_not_empty(@notifications, @meta, nil)
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Value was missing or empty.')
      is_not_empty(@notifications, @meta, '')
      expect(@notifications.notification_list.length).to eq(2)
      expect(@notifications.notification_list.last.message).to eq('Value was missing or empty.')
    end
  end

  describe 'is_integer' do
    it 'correctly validates integer fields' do
      is_integer(@notifications, @meta, '15')
      expect(@notifications.notification_list.length).to eq(0)
      is_integer(@notifications, @meta, nil)
      expect(@notifications.notification_list.length).to eq(0)
      is_integer(@notifications, @meta, '15.5')
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Value was not a whole number.')
      is_integer(@notifications, @meta, 'not an integer')
      expect(@notifications.notification_list.length).to eq(2)
      expect(@notifications.notification_list.last.message).to eq('Value was not a whole number.')
      is_integer(@notifications, @meta.merge(mandatory: true), nil)
      expect(@notifications.notification_list.length).to eq(3)
      expect(@notifications.notification_list.last.message).to eq('Value was not a whole number.')
    end
  end

  describe 'is_valid_date' do
    it 'correctly validates date fields' do
      is_valid_date(@notifications, @meta, '1992-01-10')
      expect(@notifications.notification_list.length).to eq(0)
      is_valid_date(@notifications, @meta, nil)
      expect(@notifications.notification_list.length).to eq(0)
      is_valid_date(@notifications, @meta, '1992-01-32')
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Value was not a valid timestamp.')
      is_valid_date(@notifications, @meta, 'not a date')
      expect(@notifications.notification_list.length).to eq(2)
      expect(@notifications.notification_list.last.message).to eq('Value was not a valid timestamp.')
      is_valid_date(@notifications, @meta.merge(mandatory: true), nil)
      expect(@notifications.notification_list.length).to eq(3)
      expect(@notifications.notification_list.last.message).to eq('Value was not a valid timestamp.')
    end
  end

  describe 'is_in_vocab' do
    it 'correctly validates vocabulary fields' do
      is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item']), 'test vocabulary item')
      expect(@notifications.notification_list.length).to eq(0)
      expect { is_in_vocab(@notifications, @meta, nil) }.to raise_error(ArgumentError, 'Vocabulary parameter was not specified in `meta`.')
      is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item'], mandatory: true), nil)
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Vocabulary value was empty.')
      is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item']), 'another test vocabulary item')
      expect(@notifications.notification_list.length).to eq(2)
      expect(@notifications.notification_list.last.message).to eq('Value `another test vocabulary item` was not found in the list of vocabulary terms.')
      expect { is_in_vocab(@notifications, @meta, 'another test vocabulary item') }.to raise_error(ArgumentError, 'Vocabulary parameter was not specified in `meta`.')
    end
  end

  describe 'is_boolean' do
    it 'correctly validates boolean fields' do
      is_boolean(@notifications, @meta.merge(true_value: 'true', false_value: 'false'), 'true')
      expect(@notifications.notification_list.length).to eq(0)
      is_boolean(@notifications, @meta.merge(true_value: 'true', false_value: 'false'), 'false')
      expect(@notifications.notification_list.length).to eq(0)
      is_boolean(@notifications, @meta.merge(true_value: 'yes', false_value: 'no'), 'false')
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.last.message).to eq('Value `false` was neither  `yes`, nor `no`')
      expect { is_boolean(@notifications, @meta, false) }.to raise_error(ArgumentError, 'Boolean true/false arguments were not supplied.')\
    end
  end

  describe 'row_id_exists' do
    it 'adds an error when there is server error' do
      stub_request(:get, /localhost\/select\?/).to_return(row_id_response_400)
      row_id_exists(@notifications, @meta.merge(type_name: 'identifier', type: 'resource', id_field: 'identifier'), '123')
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.first.type).to eq(:ERROR)
    end

    it 'adds an error when there is a valid response, but no match is found' do
      stub_request(:get, /localhost\/select\?/)
          .to_return(row_id_response_success([]))
      row_id_exists(@notifications, @meta.merge(type_name: 'identifier', type: 'resource', id_field: 'identifier'), '123')
      expect(@notifications.notification_list.length).to eq(1)
      expect(@notifications.notification_list.first.message).to eq('No match found for field `identifier`: 123')
    end

    it 'does not add a notification when a match is found' do
      stub_request(:get, /localhost\/select\?/)
        .to_return(row_id_response_success([Hash['primary_type', 'resource', 'identifier', '123']]))
      row_id_exists(@notifications, @meta.merge(type_name: 'identifier', type: 'resource', id_field: 'identifier'), '123')
      expect(@notifications.notification_list).to be_empty
    end
  end
end
