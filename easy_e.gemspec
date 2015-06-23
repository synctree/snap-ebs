Gem::Specification.new do |s|
  s.name        = 'easy_e'
  s.version     = '0.0.1'
  s.date        = '2015-04-21'
  s.summary     = "Easy EBS snapshots that work"
  s.description = "Easy EBS snapshots that work"
  s.authors     = ["Bryan Conrad"]
  s.email       = 'bryan.conrad@synctree.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "*.md"]
  s.executables << 'easy-e'
  s.homepage    = 'http://rubygems.org/gems/easy_e'
  s.license     = 'MIT'
  s.require_path = 'lib'
end
