Gem::Specification.new {|s|
	s.name         = 'torchat'
	s.version      = '0.0.1'
	s.author       = 'meh.'
	s.email        = 'meh@paranoici.org'
	s.homepage     = 'http://github.com/meh/ruby-torchat'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'Torchat implementation in Ruby'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_dependency 'eventmachine'
	s.add_dependency 'em-socksify'
}
