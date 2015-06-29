require 'ostruct'
class SnapEbs::Plugin
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

  protected

  # Executes the given block with error handling, and prints helpful error
  # messages when an exception is caught.
  #
  # Returns the result of the block, or nil if an exception occured
  #
  # ```
  # carefully 'reticulate splines' do
  #   splines.each &:reticulate
  # end
  # ```
  #
  def carefully msg
    yield
  rescue => e
    logger.error "Error while trying to #{msg}"
    logger.error e
    nil
  end

  def logger
    SnapEbs.logger false
  end
end

require 'plugins/mysql_plugin'
require 'plugins/mongo_plugin'