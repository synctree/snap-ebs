require 'csv'
require 'httparty'
module SnapEbs::Snapshotter
  AWS_INSTANCE_ID_URL = 'http://169.254.169.254/latest/dynamic/instance-identity/document'

  attr_writer :compute

  # Takes snapshots of attached volumes (optionally filtering by volumes
  # mounted to the given directories)
  def take_snapshots
    carefully 'take snapshots' do
      system 'sync'
      attached_volumes.collect do |vol|
        dir = device_to_directory device_name vol
        fs_freeze dir if options[:fs_freeze]
        next unless should_snap vol
        logger.debug "Snapping #{vol.id}"
        carefully "take snapshots for #{vol.id}" do
          snapshot = compute.snapshots.new
          snapshot.volume_id = vol.id
          snapshot.description = snapshot_name(vol)
          snapshot.save
          snapshot
        end
        fs_unfreeze dir if options[:fs_freeze]
      end
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

  def directory_to_device dir
    `df -T #{dir} | grep dev`.split(/\s/).first.strip
  end

  def device_to_directory device
    parts = `cat /etc/mtab | grep #{device}`.split(/\s+/)
    logger.warn "Could not find directory for #{device}" unless parts.length > 1
    parts[1]
  end

  def is_root_device? dir
    directory_to_device('/') == directory_to_device(dir)
  end

  def device_name vol
    vol.device.gsub('/dev/s', '/dev/xv') rescue vol.device
  end

  def should_snap vol
    options.directory.nil? or devices_to_snap.include?(device_name vol)
  end

  def devices_to_snap
    @devices_to_snap ||= options.directory.split(',').map { |dir| directory_to_device dir }
  end

  def fs_freeze_command
    @fs_freeze_command ||= system('which fsfreeze > /dev/null') ? 'fsfreeze' : 'xfs_freeze'
  end

  def fs_freeze dir
    return logger.warn "Refusing to freeze #{dir}, which is the root device (#{directory_to_device dir})" if is_root_device? dir
    system("#{fs_freeze_command} -f #{dir}")
  end

  def fs_unfreeze dir
    return logger.warn "Refusing to unfreeze #{dir}, which is the root device (#{directory_to_device dir})" if is_root_device? dir
    system("#{fs_freeze_command} -u #{dir}")
  end
end
