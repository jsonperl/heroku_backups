# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "heroku_backups/version"

Gem::Specification.new do |s|
  s.name        = "heroku_backups"
  s.version     = HerokuBackups::VERSION
  s.authors     = ["jsonperl"]
  s.email       = ["jason.a.pearl@gmail.com"]
  s.homepage    = "https://github.com/jsonperl/heroku_backups"
  s.summary     = %q{Heroku postgres backup and restore to Amazon S3}
  s.description = %q{Adds S3 backup and restore capabilities for your Heroku Postgres database along with matching rake tasks}

  s.add_dependency('aws-s3', '>= 0.6.2')

  s.rubyforge_project = "heroku_backups"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
