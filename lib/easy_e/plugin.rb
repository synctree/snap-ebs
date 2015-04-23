class EasyE::Plugin
  @@registered_plugins = []

  attr_accessor :options

  def self.inherited(klass)
    registered_plugins.unshift klass
  end

  def self.registered_plugins
    @@registered_plugins
  end

  def initialize
    @options = { }
  end

  def collect_options option_parser
    defined_options.each do |option_name, description|
      option_parser.on "--#{name.downcase}-#{option_name} #{option_name.upcase}", description do |val|
        options[option_name.to_sym] = val
      end
    end
  end
end

require 'plugins/mysql_plugin'