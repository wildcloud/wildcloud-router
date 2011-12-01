# Copyright (C) 2011 Marek Jelen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'amqp'
require 'yajl'

module Wildcloud
  module Router
    class Core

      def initialize
        @counter = {}
        @routes = {}

        Router.logger.info("(Core) Starting")
        connect_amqp

        Router.logger.info("(Core) Requesting synchronization")
        publish({ :node => Router.configuration["node"]["name"], :type => :sync })

        @queue.subscribe do |metadata, message|
          handle(metadata, message)
        end
      end

      def connect_amqp
        Router.logger.info("(Core) Connecting to broker")
        @amqp = AMQP.connect(Router.configuration["amqp"])
        @channel = AMQP::Channel.new(@amqp)
        # Communication infrastructure
        @topic = @channel.topic('wildcloud.router')
        @queue = @channel.queue("wildcloud.router.#{Router.configuration["node"]["name"]}")
        @queue.bind(@topic, :routing_key => "nodes")
        @queue.bind(@topic, :routing_key => "node.#{Router.configuration["node"]["name"]}")
      end

      def handle(metadata, message)
        Router.logger.debug("(Core) Got message: #{message}")
        message = Yajl::Parser.parse(message)
        method = "handle_#{message["type"]}".to_sym
        if respond_to?(method)
          send(method, message)
        else

        end
      end

      def handle_sync(data)
        @routes = data['routes']
      end

      def parse_target(target)
        target = target.split(':')
        if target.size == 1
          { "socket" => target[0] }
        else
          { "address" => target[0], "port" => target[1] }
        end
      end

      def handle_add_route(data)
        host = data['host']
        ( @routes[host] ||= [] ) << parse_target(data['target'])
      end

      def handle_remove_route(data)
        host = data['host']
        return unless @routes[host]
        @routes[host].delete(parse_target(data['target']))
      end

      def resolve(host)
        host << ':80' unless host.index(':')
        return nil unless @routes[host]
        @counter[host] ||= 0
        res = @routes[host][@counter[host]]
        @counter[host] += 1
        @counter[host] = 0 if @counter[host] == @routes[host].size
        res
      end

      def publish(message)
        Router.logger.debug("(Core) Publishing #{message.inspect}")
        @topic.publish(Yajl::Encoder.encode(message), :routing_key => 'master')
      end

    end
  end
end
