require 'csv'
require 'httparty'
require 'pp'
module EasyE::Snapshotter
  AWS_INSTANCE_ID_URL = 'http://169.254.169.254/latest/dynamic/instance-identity/document'

  attr_writer :storage, :compute, :instance_id
  def take_snapshots
    attached_volumes.collect do |vol|
      logger.debug "Snapping #{vol.volume_id}"
      snapshot = compute.snapshots.new
      snapshot.volume_id = vol.volume_id
      snapshot.save
      snapshot
    end
  end

  # lazy loaders
  def compute
    require 'fog/aws'
    @compute ||= Fog::Compute.new({
      :aws_access_key_id => access_key,
      :aws_secret_access_key => secret_key,
      :provider => "AWS"
    }) 
  end

  def attached_volumes
    @attached_volumes ||= compute.volumes.select { |vol| vol.server_id == instance_id }
  end

  def access_key
    @access_key ||= if options[:credentials_file] then credentials.first["Access Key Id"] else options[:access_key] end
  end

  def secret_key
    @secret_key ||= if options[:credentials_file] then credentials.first["Secret Access Key"] else options[:secret_key] end
  end

  def credentials
    @credentials ||= CSV.parse(File.read(options[:credentials_file]), :headers => true)
  end

  def instance_id
    @instance_id ||= JSON.parse(HTTParty.get(AWS_INSTANCE_ID_URL))["instanceId"]
  end
end