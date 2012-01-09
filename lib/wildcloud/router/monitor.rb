module Wildcloud
  module Router

    def self.monitor
      @monitor ||= Monitor.new
    end

    class Monitor

      def initialize
        @channel = AMQP::Channel.new(Core.instance.amqp)
        @topic = @channel.topic('wildcloud.monitor')
        @data = setup
        EventMachine.add_periodic_timer(1, &method(:report))
      end

      def report
        data, @data = @data, setup
        puts data.inspect
        @topic.publish(JSON.dump(data), :routing_key => 'router')
      end

      def setup
        {
            :published_at => Time.now.to_i,
            :node => Router.configuration['node']['name'],
            :count => 0,
            :inbound => 0,
            :outbound => 0,
            :time => 0,
            :target => {},
        }
      end

      def request(target, time, inbound, outbound)
        return unless target
        target = "#{target['address']}:#{target['port']}"
        @data[:count] += 1
        @data[:inbound] += inbound
        @data[:outbound] += outbound
        @data[:time] += time
        #@data[:target][target] ||= {:count => 0, :outbound => 0, :inbound => 0, :time => 0}
        #@data[:target][target][:count] += 1
        #@data[:target][target][:time] += time
        #@data[:target][target][:inbound] += inbound
        #@data[:target][target][:outbound] += outbound
      end

    end

  end
end