require './lib/snap_ebs/version'
Gem::Specification.new do |s|
  s.name        = 'snap-ebs'
  s.version     = SnapEbs::VERSION
  s.date        = '2015-07-29'
  s.summary     = "EBS backups in a snap"
  s.description = "Tested, service-aware and consistent AWS EC2 backups via EBS snapshots."
  s.authors     = ["Bryan Conrad"]
  s.email       = 'bryan.conrad@synctree.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "*.md"]
  s.executables << 'snap-ebs'
  s.homepage    = 'http://rubygems.org/gems/snap-ebs'
  s.license     = 'MIT'
  s.require_path = 'lib'
  s.add_runtime_dependency "fog", '~> 1.31'
  s.add_runtime_dependency "httparty", '~> 0.13'
  s.add_runtime_dependency "mongo", '~> 2.2'
end
