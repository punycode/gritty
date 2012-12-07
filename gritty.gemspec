# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gritty/version'

Gem::Specification.new do |gem|
  gem.name          = "gritty"
  gem.version       = Gritty::VERSION
  gem.authors       = ["punycode"]
  gem.email         = ["zh@punyco.de"]
  gem.description   = %q{Gritty enables you to write specifications of Git repository manipulations in a clean compact DSL}
  gem.summary       = %q{The swiss army knife for Git repository hackery}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('aruba')
  gem.add_development_dependency('rake', '~> 0.9.2')
  gem.add_development_dependency('archive-tar-minitar')
  gem.add_dependency('rugged', '~> 0.17.0.b6')
  gem.add_dependency('ruby-progressbar')
  gem.add_dependency('methadone', '~> 1.2.2')
end
