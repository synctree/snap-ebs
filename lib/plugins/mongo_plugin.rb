require 'pp'
class SnapEbs::Plugin::MongoPlugin < SnapEbs::Plugin
  WIRED_TIGER_KEY = 'wiredTiger'
  attr_accessor :client
  def defined_options
    {
      shutdown: 'Shutdown mongodb server (this is required if your data and journal are on different volumes',
      command: 'Command to start mongodb if the server must be shut down (i.e. multi-volume Wired Tiger)',
      retry: 'How many times to retry starting or unlocking mongodb (default: 720)',
      interval: 'Interval (in seconds) to wait when retrying (default: 5)',
      user: 'Mongo user',
      password: 'Mongo password',
      port: 'Mongo port',
      host: 'Mongo host',
      server_selection_timeout: 'Timeout in seconds while choosing a server to connect to (default 30)',
      wait_queue_timeout: 'Timeout in seconds while waiting for a connection in the pool (default 1)',
      connect_timeout: 'Timeout in seconds to wait for a socket to connect (default 5)',
      socket_timeout: 'Timeout in seconds to wait for an operation to execute on a socket (default 5)'
    }
  end

  def default_options
    {
      shutdown: false,
      command: "service mongod start",
      retry: 720,
      interval: 5,
      port: '27017',
      host: 'localhost',
      server_selection_timeout: 30,
      wait_queue_timeout: 1,
      connect_timeout: 5,
      socket_timeout: 5
    }
  end

  def before
    require 'mongo'
    Mongo::Logger.logger = logger
    return false unless carefully('check if we can operate safely') { safe_to_operate? }

    if wired_tiger?
      logger.info "Wired Tiger storage engine detected"
      carefully('stop mongo') { stop_mongo } if options.shutdown
    else
      logger.info "MMAPv1 storage engine detected"
      carefully('lock mongo') { lock_mongo }
    end

    true
  end

  def after
    unlock_or_start_mongo

    if carefully('check that mongo is still accessible') { client.command(serverStatus: 1).first }
      logger.info "Received status from mongo, everything appears to be ok"
    end
  end

  def name
    "Mongo"
  end

  private

  def unlock_or_start_mongo
    (options.retry.to_i + 1).times do
      if wired_tiger?
        return if options.shutdown && carefully('start mongo') { start_mongo }
      else
        return if carefully('unlock mongo') { unlock_mongo }
      end

      # otherwise we failed
      logger.warn "Failed to start MongoDB, retrying in #{options.interval} seconds"
      sleep options.interval.to_i
    end
  end

  def safe_to_operate?
    # we check for strict equality with booleans here, because nil means an
    # error occurred while checking, and it is unsafe to operate
    return true if (primary? == false) or (standalone? == true)
    logger.error "This appears to be a primary member, refusing to operate"
    false
  end

  def wired_tiger?
    if @wired_tiger.nil?
      @wired_tiger = carefully 'detect mongodb\'s storage engine' do
        client.command(serverStatus: 1).first.has_key? WIRED_TIGER_KEY
      end
    end
    @wired_tiger
  end

  def primary?
    if @primary.nil?
      @primary = client.command(isMaster: 1).first['ismaster']
    end
    @primary
  end

  def standalone?
    # this will raise an error on a non-RS mongod
    client.command(replSetGetStatus: 1)
    false
  rescue
    true
  end

  def stop_mongo
    logger.info 'Stopping mongodb'
    begin
      # this will always raise an exception after it completes
      client.command shutdown: 1
    rescue Mongo::Error::SocketError => e
      logger.debug "Received expected socket error after shutting down"
    end

    # we need a new connection now since the server has shut down
    @client = nil
  end

  def start_mongo
    logger.info "Starting mongodb via '#{options[:command]}'"
    system options[:command]
  end

  def lock_mongo
    logger.info "Locking mongo"
    client.command(fsync: 1, lock: true)
  end

  def unlock_mongo
    logger.info "Unlocking mongo"
    client.database['$cmd.sys.unlock'].find().read
  end

  def client
    @client ||= Mongo::Client.new [ "#{options.host}:#{options.port}" ], client_options
  end

  def client_options
    {
      connect: :direct,
      user: options.user,
      password: options.password,
      server_selection_timeout: options.server_selection_timeout.to_i,
      wait_queue_timeout: options.wait_queue_timeout.to_i,
      connect_timeout: options.connect_timeout.to_i,
      socket_timeout: options.socket_timeout.to_i
    }
  end
end