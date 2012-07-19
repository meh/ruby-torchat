Kernel.load 'lib/torchat/version.rb'

Gem::Specification.new {|s|
	s.name         = 'torchat'
	s.version      = Torchat.version
	s.author       = 'meh.'
	s.email        = 'meh@paranoici.org'
	s.homepage     = 'http://github.com/meh/ruby-torchat'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'Torchat implementation in Ruby, event-driven EventMachine based library.'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_dependency 'eventmachine', '>= 1.0.0.rc.4'
	s.add_dependency 'em-socksify'

	s.add_dependency 'iniparse'
}
