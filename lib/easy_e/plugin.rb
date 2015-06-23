require 'ostruct'
class EasyE::Plugin
  @@registered_plugins = []

  attr_reader :options, :logger

  def self.inherited(klass)
    registered_plugins.unshift klass
  end

  def self.registered_plugins
    @@registered_plugins
  end

  def default_options
    { }
  end

  def options
    @options ||= OpenStruct.new default_options
  end

  def logger
    EasyE.logger false
  end

  def collect_options option_parser
    option_parser.on "--#{name.downcase}", "Enable the #{name} plugin" do
      options.enable = true
    end

    defined_options.each do |option_name, description|
      option_parser.on "--#{name.downcase}-#{option_name.to_s.gsub('_','-')} #{option_name.upcase}", description do |val|
        options[option_name.to_sym] = val
      end
    end
  end

  def carefully msg
    yield
  rescue Exception => e
    logger.error "Error while trying to #{msg}"
    logger.error e
    nil
  end
end

require 'plugins/mysql_plugin'
require 'plugins/mongo_plugin'