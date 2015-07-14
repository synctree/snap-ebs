require 'csv'
require 'httparty'
module SnapEbs::Snapshotter
  AWS_INSTANCE_ID_URL = 'http://169.254.169.254/latest/dynamic/instance-identity/document'

  attr_writer :compute

  # Takes snapshots of attached volumes (optionally filtering by volumes
  # mounted to the given directories)
  def take_snapshots
    system 'sync'
    attached_volumes.collect do |vol|
      fs_freeze vol if options[:fs_freeze]
      next unless should_snap vol
      logger.debug "Snapping #{vol.id}"
      snapshot = compute.snapshots.new
      snapshot.volume_id = vol.id
      snapshot.description = snapshot_name(vol)
      snapshot.save
      snapshot
      fs_unfreeze vol if options[:fs_freeze]
    end
  end

  # Get the Fog compute object. When `--mock` is given, `Fog.mock!` is called
  # and  information normally auto-detected from AWS is injected with dummy
  # values to circumvent the lazy loaders.
  def compute
    require 'fog/aws'
    if options[:mock]
      Fog.mock!
      @region = 'us-east-1'
      @instance_id = 'i-deadbeef'
      @instance_name = 'totally-not-the-cia'
    end

    @compute ||= Fog::Compute.new({
      :aws_access_key_id => access_key,
      :aws_secret_access_key => secret_key,
      :region => region,
      :provider => "AWS"
    }) 
  end

  private

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

  def instance_name
    @instance_name ||= compute.servers.get(instance_id).tags['Name']
  end

  def region
    @region ||= JSON.parse(HTTParty.get(AWS_INSTANCE_ID_URL))["region"]
  end

  def snapshot_name vol
    id = instance_name
    id = instance_id if id.nil? or id.empty?
    "#{Time.now.strftime "%Y%m%d%H%M%S"}-#{id}-#{vol.device}"
  end

  def device_from_directory dir
    `df -T #{dir} | grep dev`.split(/\s/).first.strip
  end

  def is_root_device? vol
    device_from_directory('/') == device_name(vol)
  end

  def device_name vol
    vol.device.gsub('/dev/s', '/dev/xv') rescue vol.device
  end

  def should_snap vol
    options.directory.nil? or devices_to_snap.include?(device_name vol)
  end

  def devices_to_snap
    @devices_to_snap ||= options.directory.split(',').map { |dir| device_from_directory dir }
  end

  def fs_freeze_command
    @fs_freeze_command ||= system('which fsfreeze > /dev/null') ? 'fsfreeze' : 'xfs_freeze'
  end

  def fs_freeze vol
    return logger.warn "Refusing to freeze root device #{device_name vol}" if is_root_device? vol
    system("#{fs_freeze_command} -f #{device_name vol}")
  end

  def fs_unfreeze vol
    return logger.warn "Refusing to unfreeze root device #{device_name vol}" if is_root_device? vol
    system("#{fs_freeze_command} -u #{device_name vol}")
  end
end
