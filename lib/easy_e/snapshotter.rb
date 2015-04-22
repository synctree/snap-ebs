require 'csv'
require 'fog/aws'
require 'httparty'
require 'pp'
module EasyE::Snapshotter
  AWS_INSTANCE_ID_URL = 'http://169.254.169.254/latest/dynamic/instance-identity/document'

  attr_writer :storage, :compute, :instance_id
  def take_snapshots
    attached_volumes.each do |vol|
      snapshot = compute.snapshots.new
      snapshot.volume_id = vol.volume_id
      snapshot.save
    end
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

  def attached_volumes
    compute.volumes.select { |vol| vol.server_id == instance_id }
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

  def instance_id
    @instance_id ||= JSON.parse(HTTParty.get(AWS_INSTANCE_ID_URL))["instanceId"]
  end
end