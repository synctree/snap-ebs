require 'optparse'

class SnapEbs
  module Options
    def option_parser
      unless @option_parser
        @option_parser = OptionParser.new do |o|
          o.banner = "Usage: #{$0} [options]"

          o.on("-v", "--[no-]verbose", "Run verbosely") do |val|
            options[:verbose] = val
          end

          o.on("-a", "--access-key <AWS ACCESS KEY>", "AWS access key") do |val|
            options[:access_key] = val
          end

          o.on("-s", "--secret-key <AWS SECRET KEY>", "AWS secret key") do |val|
            options[:secret_key] = val
          end

          o.on("-c", "--credentials-file <FILE>", "Load AWS credentials from the downloaded CSV file (overrides -a and -s)") do |val|
            options[:credentials_file] = val
          end

          o.on("-m", "--[no-]mock", "Mock out AWS calls for testing in Vagrant") do |val|
            options[:mock] = val
          end

          o.on("-l", "--logfile FILE", "Path to a file used for logging") do |filename|
            options.logfile = filename
            logger.debug filename
          end

          o.on("-d", "--directory PATH", "Only snap volumes mounted to PATH, a comma-separated list of directories") do |d|
            options.directory = d
          end
        end

        plugins.each { |plugin| plugin.collect_options @option_parser }
      end

      @option_parser
    end
  end

  def options
    @options ||= OpenStruct.new
  end
end
