class MapValidator
  class Notifications
    attr_reader :notification_list

    def initialize()
      @notification_list = []
    end

    def add_notification(type, message = '', source = '')
      @notification_list.push(Notification.new(type, message, source))
    end

    class Notification
      def initialize(type, message, source)
        raise "Invalid type." unless [:ERROR, :WARNING, :INFO].include? type
        @type = type
        @message = message
        @source = source
      end

      attr_reader :type
      attr_reader :message
      attr_reader :source
    end
  end
end
