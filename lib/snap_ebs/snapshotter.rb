require 'csv'
require 'httparty'
module SnapEbs::Snapshotter
  AWS_INSTANCE_ID_URL = 'http://169.254.169.254/latest/dynamic/instance-identity/document'

  attr_writer :compute

  # Takes snapshots of attached volumes (optionally filtering by volumes
  # mounted to the given directories)
  def take_snapshots
    result = []
    logger.debug "Issuing sync command"
    system 'sync'

    logger.debug "Walking attached volumes"
    attached_volumes.each do |vol|
      dir = device_to_directory device_name vol
      logger.debug "Found #{vol.id} mounted on #{dir}"
      unless should_snap vol
        logger.debug "Skipping #{vol.id}"
        next
      end

      fs_freeze dir if options[:fs_freeze]
      logger.debug "Snapping #{vol.id}"
      snapshot = compute.snapshots.new
      snapshot.volume_id = vol.id
      snapshot.description = snapshot_name(vol)
      retry_on_transient_error { logger.debug snapshot.save }
      logger.debug "Snapshot saved for #{vol.id}"
      fs_unfreeze dir if options[:fs_freeze]
      result.push vol
    end
    result
  end

  # Get the Fog compute object. When `--mock` is given, `Fog.mock!` is called
  # and  information normally auto-detected from AWS is injected with dummy
  # values to circumvent the lazy loaders.
  def compute
    require 'fog/aws'
    logger.debug "Mock: #{options[:mock]}"
    if options[:mock]
      Fog.mock!
      @region = 'us-east-1'
      @instance_name = 'totally-not-the-cia'
    end

    logger.debug "AWS region auto-detected as #{region}"
    @compute ||= Fog::Compute.new({
      :aws_access_key_id => access_key,
      :aws_secret_access_key => secret_key,
      :region => region,
      :provider => "AWS"
    }) 
  end

  private

  def attached_volumes
    logger.debug "Querying for volumes attached to this instance #{instance_id}"
    @attached_volumes ||= (retry_on_transient_error { compute.volumes.select { |vol| vol.server_id == instance_id } } || [])
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
    if options[:mock]
      @instance_id = 'i-deadbeef'
    else
      @instance_id ||= JSON.parse(HTTParty.get(AWS_INSTANCE_ID_URL))["instanceId"]
    end
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
    logger.debug "Preparing to freeze #{dir}"
    return logger.warn "Refusing to freeze #{dir}, which is the root device (#{directory_to_device dir})" if is_root_device? dir
    system("#{fs_freeze_command} -f #{dir}")
  end

  def fs_unfreeze dir
    logger.debug "Preparing to unfreeze #{dir}"
    return logger.warn "Refusing to unfreeze #{dir}, which is the root device (#{directory_to_device dir})" if is_root_device? dir
    system("#{fs_freeze_command} -u #{dir}")
  end

  # Retries the given block options.retry_count times while it raises transient AWS
  # API errors. Returns nil if the number of attempts has been exceeded
  def retry_on_transient_error
    (options.retry_count.to_i + 1).times do |n|
      logger.debug "Attempt ##{n}"
      begin
        result = yield
      rescue Fog::Compute::AWS::Error => e
        sleep_seconds = options.retry_interval * (n+1)
        logger.warn "Received AWS error: #{e}"
        logger.warn "Sleeping #{sleep_seconds} seconds before retrying"
        sleep sleep_seconds
      else
        return result
      end
    end
    nil
  end
end
