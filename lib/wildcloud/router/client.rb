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

require 'http/parser'

module Wildcloud
  module Router
    module Client

      def initialize(proxy)
        @proxy = proxy
        @closed = false
        @parser = Http::Parser.new(self)
        @buffer = []
        @time = Time.now
      end

      def closed?
        @closed
      end

      def post_init
        Router.logger.debug("(Proxy client) Client connected")
        @proxy.buffer.each do |chunk|
          send_data(chunk)
        end
        Router.logger.debug("(Proxy client) Enabling native proxy")
        EventMachine.enable_proxy(@proxy, self)
      end

      def receive_data(data)
        @buffer << data
        @parser << data
      rescue Http::Parser::Error => error
        Router.logger.debug("(Proxy client) Error #{error}")
      end

      def on_headers_complete(headers)
        @buffer.each do |chunk|
          @proxy.send_data(chunk)
        end
        EventMachine.enable_proxy(self, @proxy)
      end

      def unbind
        @closed = true
        @proxy.close_connection(true) if @proxy and !@proxy.closed?
        Router.logger.debug("(Proxy client) Client disconnected (#{(Time.now - @time) * 1000})")
      end

      def send_line(data)
        send_data("#{data}\r\n")
      end

    end
  end
end
