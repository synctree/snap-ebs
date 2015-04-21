module EasyE::Options
  def option_parser
    @option_parser =  OptionParser.new do |o|
      o.banner = "Usage: #{$0} [options]"

      o.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
    end
  end
end