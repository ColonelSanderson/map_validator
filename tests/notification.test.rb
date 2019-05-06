require 'test/unit'
require_relative '../src/ValidatorFunctions'

class TestNotifications < Test::Unit::TestCase

  def setup
    @notifications = Notifications.new
    @meta = {}
  end

  def test_format_source
    assert_raise(RuntimeError, 'Invalid type.') { @notifications.add_notification('CATASTROPHIC_ERROR') }
    assert_nothing_raised (RuntimeError) { @notifications.add_notification('ERROR') }
    @notifications.add_notification('WARNING', 'The was a problem, but only a little one.', 'C17')
    assert_equal(@notifications.notification_list[1].message, 'The was a problem, but only a little one.')
    assert_equal(@notifications.notification_list[1].source, 'C17')
    @notifications.add_notification('WARNING', 'The was a noteworthy event, but not necessarily a dangerous one', 'C17');
    assert_equal(@notifications.notification_list.count, 3)
  end

end