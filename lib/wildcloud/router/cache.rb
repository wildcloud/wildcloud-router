module Wildcloud
  module Router
    class Cache

      def self.put(target, connection)
        @connections ||= {}
        @connections[target] ||= []
        @connections << connection
      end

      def self.get(target)
        @connections ||= {}
        @connections[target] ||= []
        @connections[target].shift
      end

      def self.inspect
        @connections.inspect
      end

    end
  end
end