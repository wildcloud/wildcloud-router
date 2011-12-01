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

require 'wildcloud/router/configuration'
require 'wildcloud/router/logger'
require 'wildcloud/router/core'
require 'wildcloud/router/proxy'

module Wildcloud
  module Router
    class Server

      def self.start
        Router.logger.info('(Server) Starting')
        @core = Wildcloud::Router::Core.new
        addr = Router.configuration['http']['address']
        port = Router.configuration['http']['port']
        EventMachine.start_server(addr, port, Router::Proxy, @core)
        Router.logger.info('(Server) Started')
      end

    end
  end
end
