Gem::Specification.new do |s|

  s.name             = 'algebrick'
  s.version          = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.date             = '2013-05-14'
  s.summary          = 'Algebraic types and pattern matching for Ruby'
  s.description      = 'Provides algebraic type definitions and pattern matching'
  s.authors          = ['Petr Chalupa']
  s.email            = 'git@pitr.ch'
  s.homepage         = 'https://github.com/pitr-ch/algebrick'
  s.extra_rdoc_files = %w(LICENSE README.md README_FULL.md VERSION)
  s.files            = Dir['lib/algebrick.rb'] + %w(VERSION)
  s.require_paths    = %w(lib)
  s.license          = 'MIT'
  s.test_files       = Dir['spec/algebrick.rb']

  #{}.each do |gem, version|
  #  s.add_runtime_dependency(gem, [version || '>= 0'])
  #end

  %w(minitest minitest-reporters turn pry yard redcarpet github-markup multi_json).each do |gem|
    s.add_development_dependency gem, '>= 0'
  end
end

