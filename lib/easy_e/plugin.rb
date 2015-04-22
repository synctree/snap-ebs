class EasyE::Plugin
  @@plugins = []
  def self.inherited(klass)
    plugins.unshift klass
  end

  def self.plugins
    @@plugins
  end
end

require 'plugins/mysql'