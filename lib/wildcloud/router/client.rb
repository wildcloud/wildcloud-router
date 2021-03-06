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

module Wildcloud
  module Router
    module Client

      def initialize(target)
        @target = target
        @closed = false
      end

      # EventMachine

      def post_init
        @parser = Http::ResponseParser.new(self)
      end

      def receive_data(data)
        @outbound += data.size
        @parser << data
      rescue Http::Parser::Error => error
        Router.logger.debug('Proxy client') { "Error #{error}" }
      end

      def unbind
        @parser = nil
        @stop_time = Time.now
        Router.monitor.request(@target, @stop_time - @proxy.start_time, @inbound, @outbound)
        @closed = true
        @proxy.close_connection(true) if @proxy and !@proxy.closed?
      end

      # HTTP parser

      def on_headers_complete(headers)
        @proxy.send_line("HTTP/#{@parser.http_version.join('.')} #{@parser.status_code} #{CODE[@parser.status_code]}")
        headers.each do |name, value|
          @proxy.send_line("#{name}: #{value}")
        end
        @proxy.send_line('')
      end

      def on_body(chunk)
        @proxy.send_data(chunk)
      end

      def on_message_complete
        close_connection
      end

      # Tools

      def make_request(proxy, version, method, url, headers)
        @proxy = proxy
        @inbound = 0
        @outbound = 0
        send_line("#{method} #{url} HTTP/#{version}")
        headers.each do |name, value|
          send_line("#{name}: #{value}")
        end
        send_line('')
      end

      def send_data(data)
        @inbound += data.size
        super(data)
      end

      def closed?
        @closed
      end

      def send_line(data)
        send_data("#{data}\r\n")
      end

      # Borrowed from em-http-request
      CODE = {
            100  => 'Continue',
            101  => 'Switching Protocols',
            102  => 'Processing',
            200  => 'OK',
            201  => 'Created',
            202  => 'Accepted',
            203  => 'Non-Authoritative Information',
            204  => 'No Content',
            205  => 'Reset Content',
            206  => 'Partial Content',
            207  => 'Multi-Status',
            226  => 'IM Used',
            300  => 'Multiple Choices',
            301  => 'Moved Permanently',
            302  => 'Found',
            303  => 'See Other',
            304  => 'Not Modified',
            305  => 'Use Proxy',
            306  => 'Reserved',
            307  => 'Temporary Redirect',
            400  => 'Bad Request',
            401  => 'Unauthorized',
            402  => 'Payment Required',
            403  => 'Forbidden',
            404  => 'Not Found',
            405  => 'Method Not Allowed',
            406  => 'Not Acceptable',
            407  => 'Proxy Authentication Required',
            408  => 'Request Timeout',
            409  => 'Conflict',
            410  => 'Gone',
            411  => 'Length Required',
            412  => 'Precondition Failed',
            413  => 'Request Entity Too Large',
            414  => 'Request-URI Too Long',
            415  => 'Unsupported Media Type',
            416  => 'Requested Range Not Satisfiable',
            417  => 'Expectation Failed',
            422  => 'Unprocessable Entity',
            423  => 'Locked',
            424  => 'Failed Dependency',
            426  => 'Upgrade Required',
            500  => 'Internal Server Error',
            501  => 'Not Implemented',
            502  => 'Bad Gateway',
            503  => 'Service Unavailable',
            504  => 'Gateway Timeout',
            505  => 'HTTP Version Not Supported',
            506  => 'Variant Also Negotiates',
            507  => 'Insufficient Storage',
            510  => 'Not Extended'
          }

    end
  end
end
