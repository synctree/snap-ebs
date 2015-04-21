require 'logger'
class EasyE
  attr_accessor :logger
  def initialize(logger = false)
    @logger = (logger or Logger.new(false))
    @logger.debug "Debug logging enabled"
  end

  def option_parser
    OptionParser.new do |o|
      o.banner = "Usage: #{$0} [options]"

      o.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
    end
  end
end