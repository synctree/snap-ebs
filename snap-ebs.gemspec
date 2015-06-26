Gem::Specification.new do |s|
  s.name        = 'snap-ebs'
  s.version     = '0.0.8'
  s.date        = '2015-06-26'
  s.summary     = "Easy EBS snapshots that work"
  s.description = "Easy EBS snapshots that work"
  s.authors     = ["Bryan Conrad"]
  s.email       = 'bryan.conrad@synctree.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "*.md"]
  s.executables << 'snap-ebs'
  s.homepage    = 'http://rubygems.org/gems/snap-ebs'
  s.license     = 'MIT'
  s.require_path = 'lib'
  s.add_runtime_dependency "fog", '~> 1.31'
  s.add_runtime_dependency "httparty", '~> 0.13'
  s.add_runtime_dependency "mysql", '~> 2.9'
  s.add_runtime_dependency "mongo", '~> 2.0'
end
