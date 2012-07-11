$:.push File.expand_path("../lib", __FILE__)
require "cv_collector/version"

Gem::Specification.new do |gem|
  gem.name    = "cv_collector"
  gem.version = CvCollector::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.author      = "CvCollector"
  gem.email       = "support@cloudvertical.com"
  gem.homepage    = "http://www.cloudvertical.com/"
  gem.summary     = "Gateway library and CLI to interact with CloudVertical API."
  gem.description = "Gateway library and CLI to interact with CloudVertical API."

  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test|scripts/)} }
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  
  gem.add_dependency "faraday", "0.8.1"
  gem.add_dependency "faraday_middleware", "0.8.7"
  gem.add_dependency "yajl-ruby", "1.1.0"
  gem.add_dependency "mechanize", "2.0.1"
  gem.add_dependency "right_aws", "~> 3.0.1"
  gem.add_dependency "aws-sdk", "~> 1.5.5"
  gem.require_paths = ["lib"]  
end
