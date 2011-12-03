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

require 'wildcloud/router/client'

module Wildcloud
  module Router
    module Proxy

      attr_reader :core, :headers, :buffer, :head

      def initialize(core)
        @core = core
        @parser = Http::Parser.new(self)
        @buffer = []
        @closed = false
      end

      def post_init
        Router.logger.debug("(Proxy) New client connected")
      end

      def closed?
        @closed
      end

      def receive_data(data)
        @buffer << data
        @parser << data
      rescue HTTP::Parser::Error => error
        Router.logger.error("(Proxy) Error during parsing #{e.message}")
      end

      def unbind
        Router.logger.debug("(Proxy) Client disconnected")
        @closed = true
        @client.close_connection(true) if @client and !@client.closed?
      end

      def on_headers_complete(headers)
        host = headers['Host']
        return bad_request unless host
        Router.logger.debug("(Proxy) Client requests #{host}")
        target = @core.resolve(host)
        return bad_request unless target
        Router.logger.debug("(Proxy) Client targets to #{target.inspect}")
        if target["socket"]
          @client = EventMachine.connect(target["socket"], Router::Client, self)
        else
          @client = EventMachine.connect(target["address"], target["port"], Router::Client, self)
        end
      end

      def bad_request
        Router.logger.debug("(Proxy) Client issued bad request")
        close_connection(true)
      end

      def on_body(chunk)
        @buffer << chunk
      end

    end
  end
end
