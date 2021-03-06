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

require 'wildcloud/router/configuration'
require 'wildcloud/router/logger'
require 'wildcloud/router/core'
require 'wildcloud/router/proxy'

module Wildcloud
  module Router
    class Server

      def self.start
        Router.logger.info('Server') { 'Starting' }
        addr = Router.configuration['http']['address']
        port = Router.configuration['http']['port']
        EventMachine.start_server(addr, port, Router::Proxy, Wildcloud::Router::Core.instance)
        Router.logger.info('Server') { 'Started' }
      end

    end
  end
end
