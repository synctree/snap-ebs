require 'optparse'

class SnapEbs
  module Options
    # Gets the root `option_parser`. Plugins do not append to this directly,
    # but instead supply a list of options, arguments, descriptions, and
    # default values. `SnapEbs` manages the namespacing of options, and each
    # plugin receives its own `options` object.
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
          end

          o.on("-f", "--fs-freeze", "Freeze filesystems for fsfreeze or xfs_freeze before snapping (unfreezes after)") do |fs_freeze|
            options.fs_freeze = fs_freeze
          end

          o.on("-d", "--directory PATH", "Only snap volumes mounted to PATH, a comma-separated list of directories") do |d|
            options.directory = d
          end

          o.on("", "--version", "Show version and exit") do |d|
            puts "snap-ebs v#{::SnapEbs::VERSION}"
            exit 0
          end
        end

        plugins.each { |plugin| plugin.collect_options @option_parser }
      end

      @option_parser
    end
  end

  # Get the root `options` object, and instance of OpenStruct
  def options
    @options ||= OpenStruct.new
  end
end
