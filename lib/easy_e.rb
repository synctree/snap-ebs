require 'logger'

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
    @options = { }
    @logger = (logger or Logger.new(false))
    @logger.debug "Debug logging enabled"
  end

  def registered_plugins
    EasyE::Plugin.registered_plugins
  end
end