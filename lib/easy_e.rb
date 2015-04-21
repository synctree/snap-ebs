require 'logger'

class EasyE
end

require 'easy_e/options'

class EasyE
  include EasyE::Options
  attr_accessor :logger, :options
  def initialize(logger = false)
    @options = { }
    @logger = (logger or Logger.new(false))
    @logger.debug "Debug logging enabled"
  end
end