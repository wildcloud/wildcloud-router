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
      Router.logger.info("(Configuration) Loading from file #{file}")
      @configuration = YAML.load_file(file)
    end
  end
end
