# Copyright 2011 Marek Jelen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'amqp'
require 'singleton'

module Wildcloud
  module Router
    class Core

      include Singleton

      attr_reader :amqp

      def initialize
        @counter = {}
        @routes = {}

        Router.logger.info('Core') { "Starting" }
        connect_amqp

        Router.logger.info('Core') { "Requesting synchronization" }
        publish({ :node => Router.configuration["node"]["name"], :type => :sync })

        @queue.subscribe do |metadata, message|
          handle(metadata, message)
        end
      end

      def connect_amqp
        Router.logger.info('Core') { "Connecting to broker" }
        @amqp = AMQP.connect(Router.configuration["amqp"])
        Router.logger_add_amqp(@amqp)
        @channel = AMQP::Channel.new(@amqp)
        # Communication infrastructure
        @topic = @channel.topic('wildcloud.router')
        @queue = @channel.queue("wildcloud.router.#{Router.configuration["node"]["name"]}")
        @queue.bind(@topic, :routing_key => "nodes")
        @queue.bind(@topic, :routing_key => "node.#{Router.configuration["node"]["name"]}")
      end

      def handle(metadata, message)
        Router.logger.debug('Core') { "Got message: #{message}" }
        message = ::JSON.parse(message)
        method = "handle_#{message["type"]}".to_sym
        if respond_to?(method)
          send(method, message)
        else

        end
      end

      def handle_sync(data)
        @routes = data['routes']
      end

      def parse_target(raw_target)
        target = raw_target.split(':')
        if target.size == 1
          { "socket" => target[0]}
        else
          { "address" => target[0], "port" => target[1]}
        end
      end

      def handle_add_route(data)
        host = data['host']
        ( @routes[host] ||= [] ) << parse_target(data['target'])
        Router.logger.debug('Core') { "Routes: #{@routes.inspect}" }
      end

      def handle_remove_route(data)
        host = data['host']
        return unless @routes[host]
        @routes[host].delete(parse_target(data['target']))
        Router.logger.debug('Core') { "Routes: #{@routes.inspect}" }
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
        Router.logger.debug('Core') { "Publishing #{message.inspect}" }
        @topic.publish(::JSON.dump(message), :routing_key => 'master')
      end

    end
  end
end
