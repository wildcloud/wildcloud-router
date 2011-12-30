require File.expand_path('../lib/wildcloud/router/version', __FILE__)

desc 'Build wildcloud-router gem'
task :build do
  puts `gem build wildcloud-router.gemspec`
end

desc 'Install latest version'
task :install => :build do
  puts `gem install wildcloud-router-#{Wildcloud::Router::VERSION}.gem`
end