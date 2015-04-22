require 'csv'
require 'fog/aws'
require 'pp'
module EasyE::Snapshotter
  attr_writer :storage, :compute
  def take_snapshots
    pp compute.servers
    pp compute.volumes
    { foo: 'bar' }
  end

  def compute
    unless @compute
      @compute = Fog::Compute.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key,
        :provider => "AWS"
      }) 
    end

    @compute
  end

  def access_key
    unless @access_key
      if options[:credentials_file]
        @access_key = credentials.first["Access Key Id"]
      else
        @access_key = options[:access_key]
      end
    end
    @access_key
  end

  def secret_key
    unless @secret_key
      if options[:credentials_file]
        @secret_key = credentials.first["Secret Access Key"]
      else
        @secret_key = options[:secret_key]
      end
    end
    @secret_key
  end

  def credentials
    unless @credentials
      @credentials = CSV.parse(File.read(options[:credentials_file]), :headers => true)
    end

    @credentials
  end
end