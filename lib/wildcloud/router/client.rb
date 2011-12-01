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

module Wildcloud
  module Router
    module Client

      def initialize(proxy)
        @proxy = proxy
        @closed = false
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
        EventMachine.enable_proxy(self, @proxy)
      end

      def receive_data(data)
        Router.logger.error("(Proxy client) Received response data")
      end

      def unbind
        Router.logger.debug("(Proxy client) Client disconnected")
        @closed = true
        @proxy.close_connection(true) if @proxy and !@proxy.closed?
      end

      def send_line(data)
        send_data("#{data}\r\n")
      end

    end
  end
end
