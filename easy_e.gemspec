Gem::Specification.new do |s|
  s.name        = 'easy_e'
  s.version     = '0.0.6'
  s.date        = '2015-06-24'
  s.summary     = "Easy EBS snapshots that work"
  s.description = "Easy EBS snapshots that work"
  s.authors     = ["Bryan Conrad"]
  s.email       = 'bryan.conrad@synctree.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "*.md"]
  s.executables << 'easy-e'
  s.homepage    = 'http://rubygems.org/gems/easy_e'
  s.license     = 'MIT'
  s.require_path = 'lib'
  s.add_runtime_dependency "fog"
  s.add_runtime_dependency "httparty"
  s.add_runtime_dependency "mysql"
  s.add_runtime_dependency "mongo"
end
