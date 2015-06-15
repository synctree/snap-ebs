require 'logger'
require 'ostruct'

class EasyE
end

require 'easy_e/options'
require 'easy_e/snapshotter'
require 'easy_e/plugin'

class EasyE
  include EasyE::Options
  include EasyE::Snapshotter

  attr_accessor :logger, :options
  def initialize(logger = false)
    @options = OpenStruct.new
    @logger = (logger or Logger.new(false))
    @logger.debug "Debug logging enabled"
  end

  def plugins
    @plugins ||= registered_plugins.collect { |klass| klass.new logger }
  end

  def registered_plugins
    EasyE::Plugin.registered_plugins
  end

  def run
    plugins.each do |plugin|
      begin
        plugin.before if plugin.options.enable
      rescue Exception => e
        logger.error "Encountered error while running the #{plugin.name} plugin's before hook"
        logger.error e
      end
    end

    take_snapshots

    plugins.each do |plugin|
      begin
        plugin.after if plugin.options.enable
      rescue Exception => e
        logger.error "Encountered error while running the #{plugin.name} plugin's after hook"
        logger.error e
      end
    end
  end
end