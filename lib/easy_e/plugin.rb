class EasyE::Plugin
  @@registered_plugins = []
  def self.inherited(klass)
    registered_plugins.unshift klass
  end

  def self.registered_plugins
    @@registered_plugins
  end
end

require 'plugins/mysql'