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

module Wildcloud
  module Router
    module Proxy

      attr_reader :core, :request_headers, :buffer, :request_version, :request_method, :request_url

      def initialize(core)
        @core = core
        @parser = Http::Parser.new(self)
        @buffer = []
        @closed = false
        @time = Time.now
      end

      def post_init
      end

      def closed?
        @closed
      end

      def receive_data(data)
        @parser << data
      rescue HTTP::Parser::Error => error
        Router.logger.debug('Proxy') { "Error during parsing #{error.message}" }
      end

      def unbind
        @closed = true
        @client.close_connection(true) if @client and !@client.closed?
      end

      def on_headers_complete(headers)
        @request_headers = headers
        @request_version = @parser.http_version.join('.')
        @request_method = @parser.http_method
        @request_url = @parser.request_url
        return bad_request unless @request_headers['Host']
        target = @core.resolve(@request_headers['Host'])
        return bad_request unless target
        if target["socket"]
          @client = EventMachine.connect(target["socket"], Router::Client, self)
        else
          @client = EventMachine.connect(target["address"], target["port"], Router::Client, self)
        end
      end

      def bad_request
        close_connection(true)
      end

      def on_body(chunk)
        @buffer << chunk
      end

      def send_line(data)
        send_data("#{data}\r\n")
      end

    end
  end
end
