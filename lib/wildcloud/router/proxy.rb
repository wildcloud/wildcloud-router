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

require 'http/parser'

require 'wildcloud/router/client'
require 'wildcloud/router/monitor'

module Wildcloud
  module Router
    module Proxy

      attr_reader :core, :start_time

      def initialize(core)
        @core = core
        @closed = false
      end

      # EventMachine

      def post_init
      end

      def receive_data(data)
        @parser ||= Http::RequestParser.new(self)
        @parser << data
      rescue HTTP::Parser::Error => error
        Router.logger.debug('Proxy') { "Error during parsing #{error.message}" }
      end

      def unbind
        @closed = true
        @client.close_connection(true) if @client and !@client.closed?
      end

      # HTTP parser

      def on_message_begin
        @start_time = Time.now
      end

      def on_headers_complete(headers)
        return bad_request unless headers['Host']
        target = @core.resolve(headers['Host'])
        return bad_request unless target
        if target["socket"]
          @client = EventMachine.connect(target["socket"], Router::Client, target)
        else
          @client = EventMachine.connect(target["address"], target["port"], Router::Client, target)
        end
        @client.make_request(self, @parser.http_version.join('.'), @parser.http_method, @parser.request_url, headers)
      end

      def on_body(chunk)
        @client.send_data(chunk)
      end

      def on_message_complete
        @parser = nil
      end

      # Tools

      def closed?
        @closed
      end

      def bad_request
        close_connection(true)
        :stop
      end

      def send_line(data)
        send_data("#{data}\r\n")
      end

    end
  end
end
