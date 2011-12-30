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
require 'yaml'

require 'wildcloud/router/logger'

module Wildcloud
  module Router
    def self.configuration
      return @configuration if @configuration
      file = '/etc/wildcloud/router.yml'
      unless File.exists?(file)
        file = './router.yml'
      end
      Router.logger.info('Config') { "Loading from file #{file}" }
      @configuration = YAML.load_file(file)
    end
  end
end
