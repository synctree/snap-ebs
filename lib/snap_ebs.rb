$:.unshift File.dirname __FILE__
require 'logger'
require 'ostruct'
require 'snap_ebs/options'
require 'snap_ebs/snapshotter'
require 'snap_ebs/plugin'

class SnapEbs
  include SnapEbs::Options
  include SnapEbs::Snapshotter

  @@logger = nil
  def self.logger logfile
    unless @@logger
      @@logger = Logger.new(logfile || STDOUT)
      @@logger.level = Logger::DEBUG
      @@logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{severity}] #{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{msg}\n"
      end
    end

    @@logger
  end

  def self.logger= logger_
    @@logger = logger_
  end

  def plugins
    @plugins ||= registered_plugins.collect { |klass| klass.new }
  end

  def registered_plugins
    SnapEbs::Plugin.registered_plugins
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

  def execute
    option_parser.parse!
    logger.debug "Debug logging enabled"
    run
  end

  def logger
    # HACK -- the logfile argument only gets used on the first invocation
    SnapEbs.logger options.logfile
  end
end