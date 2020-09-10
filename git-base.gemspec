# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = 'git-base'
  gem.version       = "0.1"
  gem.authors       = ['Steve Tuckner']
  gem.email         = ['stevetuckner@gmail.com']
  gem.licenses      = ['MIT']
  gem.description   = %q{A library to allow the storage of portions of a database in git}
  gem.summary       = %q{
                        This allows the tracking of database record changes using git, so that
                        the database can have a history, be branched and merged.
                      }
  gem.homepage      = 'https://github.com/boberetezeke/git-base'
  gem.rdoc_options << '--main' << 'README' <<
                      '--line-numbers' <<
                      '--include' << 'opal'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
