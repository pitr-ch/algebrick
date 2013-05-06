Gem::Specification.new do |s|

  s.name             = 'algebrick'
  s.version          = '0.0.1'
  s.date             = '2013-04-21'
  s.summary          = 'Algebraic types and pattern matching'
  s.description      = 'Provides algebraic type definitions and pattern matching'
  s.authors          = ['Petr Chalupa']
  s.email            = 'git@pitr.ch'
  s.homepage         = 'https://github.com/pitr-ch/algebrick'
  #s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.extra_rdoc_files = %w(MIT-LICENSE)
  s.files            = Dir['lib/algebrick.rb']
  s.require_paths    = %w(lib)
  s.test_files       = Dir['spec/algebrick.rb']

  #{}.each do |gem, version|
  #  s.add_runtime_dependency(gem, [version || '>= 0'])
  #end

  { 'minitest' => nil,
    'turn'     => nil,
    'pry'      => nil,
    'yard'     => nil,
    'kramdown' => nil,
  }.each do |gem, version|
    s.add_development_dependency(gem, [version || '>= 0'])
  end
end

