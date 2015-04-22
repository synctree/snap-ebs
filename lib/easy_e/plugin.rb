class EasyE::Plugin
  @@registered_plugins = []

  def self.inherited(klass)
    registered_plugins.unshift klass
  end

  def self.registered_plugins
    @@registered_plugins
  end

  def collect_options option_parser
    defined_options.each do |name, description|
      option_parser.on nil, "--#{name}", description do |val| end
    end
  end
end

require 'plugins/mysql'