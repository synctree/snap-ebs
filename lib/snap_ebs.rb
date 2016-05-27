$:.unshift File.dirname __FILE__
require 'logger'
require 'ostruct'
require 'snap_ebs/options'
require 'snap_ebs/snapshotter'
require 'snap_ebs/plugin'
require 'snap_ebs/version'

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

  # Executes plugin before hooks, takes the snapshot, then runs the after
  # hooks. Plugin hooks are called within `rescue` blocks to isolate errors
  # from affecting other plugins or the snapshot plugins. Note that non-
  # standard exceptions (i.e. out of memory or keyboard interrupt) will still
  # cause a execution to abort.
  def run
    ok = true
    plugins.each do |plugin|
      next unless plugin.options.enable
      begin
        # we don't snap unless all plugin.before calls return a truthy value
        unless plugin.before
          plugin.options.enable = false
          ok = false
        end
      rescue => e
        logger.error "Encountered error while running the #{plugin.name} plugin's before hook"
        logger.error e
      end
    end

    take_snapshots if ok

    plugins.each do |plugin|
      begin
        plugin.after if plugin.options.enable
      rescue => e
        logger.error "Encountered error while running the #{plugin.name} plugin's after hook"
        logger.error e
      end
    end
  end

  # Entry point for the `snap-ebs` binary
  def execute
    option_parser.parse!
    logger.debug "Debug logging enabled"
    begin
      run
    rescue Exception => e
      logger.fatal "Encountered exception #{e}"
      e.backtrace.map { |x| logger.fatal x }
    end
  end

  # Get the global logger instance
  # `logger.debug 'reticulating splines'`
  def logger
    # HACK -- the logfile argument only gets used on the first invocation
    SnapEbs.logger options.logfile
  end
end