class MapValidator
  class Notifications
    attr_reader :notification_list

    def initialize()
      @notification_list = []
    end

    def enable_debug
      @debug = true
    end

    def add_notification(type, message = '', source = '')
      # Don't report DEBUG messages unless we've asked for them
      return if type == :DEBUG && !@debug

      @notification_list.push(Notification.new(type, message, source))
    end

    class Notification
      def initialize(type, message, source)
        raise "Invalid type." unless [:DEBUG, :ERROR, :WARNING, :INFO].include? type
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
