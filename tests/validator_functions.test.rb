require 'test/unit'
require_relative '../lib/validator_functions'
require_relative '../lib/notifications'

class TestNotifications < Test::Unit::TestCase

  def setup
    @notifications = Notifications.new
    @meta = { col: '10', row: 'Test' }
  end

  def test_notifications
    assert_raise(RuntimeError, 'Invalid type.') { @notifications.add_notification('CATASTROPHIC_ERROR') }
    assert_nothing_raised (RuntimeError) { @notifications.add_notification(:ERROR) }
    @notifications.add_notification(:WARNING, 'There was a problem, but only a little one.', 'C17')
    assert_equal('There was a problem, but only a little one.', @notifications.notification_list[1].message)
    assert_equal('C17', @notifications.notification_list[1].source)
    @notifications.add_notification(:WARNING, 'The was a noteworthy event, but not necessarily a dangerous one', 'C17');
    assert_equal(3, @notifications.notification_list.count)
  end

  def test_is_not_nil
    is_not_nil(@notifications, @meta, 'test-value')
    assert_equal(0, @notifications.notification_list.length)
    is_not_nil(@notifications, @meta, nil)
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Value was missing.', @notifications.notification_list.last.message)
  end

  def test_is_not_empty

    is_not_empty(@notifications, @meta, 'test-value')
    assert_equal(0, @notifications.notification_list.length)
    is_not_empty(@notifications, @meta, nil)
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Value was missing or empty.', @notifications.notification_list.last.message)
    is_not_empty(@notifications, @meta, '')
    assert_equal(2, @notifications.notification_list.length)
    assert_equal('Value was missing or empty.', @notifications.notification_list.last.message)
  end

  def test_is_integer
    is_integer(@notifications, @meta, '15')
    assert_equal(0, @notifications.notification_list.length)
    is_integer(@notifications, @meta, nil)
    assert_equal(0, @notifications.notification_list.length)
    is_integer(@notifications, @meta, '15.5')
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Value was not a whole number.', @notifications.notification_list.last.message)
    is_integer(@notifications, @meta, 'not an integer')
    assert_equal(2, @notifications.notification_list.length)
    assert_equal('Value was not a whole number.', @notifications.notification_list.last.message)
    is_integer(@notifications, @meta.merge(mandatory: true), nil)
    assert_equal(3, @notifications.notification_list.length)
    assert_equal('Value was not a whole number.', @notifications.notification_list.last.message)
  end

  def test_is_valid_date
    is_valid_date(@notifications, @meta, '1992-01-10')
    assert_equal(0, @notifications.notification_list.length)
    is_valid_date(@notifications, @meta, nil)
    assert_equal(0, @notifications.notification_list.length)
    is_valid_date(@notifications, @meta, '1992-01-32')
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Value was not a valid timestamp.', @notifications.notification_list.last.message)
    is_valid_date(@notifications, @meta, 'not a date')
    assert_equal(2, @notifications.notification_list.length)
    assert_equal('Value was not a valid timestamp.', @notifications.notification_list.last.message)
    is_valid_date(@notifications, @meta.merge(mandatory: true), nil)
    assert_equal(3, @notifications.notification_list.length)
    assert_equal('Value was not a valid timestamp.', @notifications.notification_list.last.message)
  end


  def test_is_in_vocab
    is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item']), 'test vocabulary item')
    assert_equal(0, @notifications.notification_list.length)
    assert_raise(ArgumentError, 'Vocabulary parameter was not specified in `meta`.') { is_in_vocab(@notifications, @meta, nil) }
    is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item'], mandatory: true), nil)
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Vocabulary value was empty.', @notifications.notification_list.last.message)
    is_in_vocab(@notifications, @meta.merge(vocabulary: ['test vocabulary item']), 'another test vocabulary item')
    assert_equal(2, @notifications.notification_list.length)
    assert_equal('Value `another test vocabulary item` was not found in the list of vocabulary terms.', @notifications.notification_list.last.message)
    assert_raise(ArgumentError, 'Vocabulary parameter was not specified in `meta`.') { is_in_vocab(@notifications, @meta, 'another test vocabulary item') }

  end

  def test_is_boolean
    is_boolean(@notifications, @meta.merge(true_value: 'true', false_value: 'false'), 'true')
    assert_equal(0, @notifications.notification_list.length)
    is_boolean(@notifications, @meta.merge(true_value: 'true', false_value: 'false'), 'false')
    assert_equal(0, @notifications.notification_list.length)
    is_boolean(@notifications, @meta.merge(true_value: 'yes', false_value: 'no'), 'false')
    assert_equal(1, @notifications.notification_list.length)
    assert_equal('Value `false` was neither  `yes`, nor `no`', @notifications.notification_list.last.message)
    assert_raise(ArgumentError, 'boolean true/false arguments were not supplied.') { is_boolean(@notifications, @meta, false) }
  end
end
