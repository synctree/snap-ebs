require 'pp'
class EasyE::Plugin::MongoPlugin < EasyE::Plugin
  WIRED_TIGER_KEY = 'wiredTiger'
  attr_accessor :client
  def defined_options
    {
      service: 'Service to start after shutting down server',
      shutdown: 'Shutdown mongodb server (this is required if your data and journal are on different volumes',
      user: 'Mongo user',
      password: 'Mongo password',
      port: 'Mongo port',
      host: 'Mongo host',
      server_selection_timeout: 'Timeout in seconds while choosing a server to connect to (default 30)',
      wait_queue_timeout: 'Timeout in seconds while waiting for a connection in the pool (default 1)',
      connection_timeout: 'Timeout in seconds to wait for a socket to connect (default 5)',
      socket_timeout: 'Timeout in seconds to wait for an operation to execute on a socket (default 5)'
    }
  end

  def default_options
    {
      service: 'mongodb',
      port: '27017',
      shutdown: false,
      host: 'localhost',
      server_selection_timeout: 30,
      wait_queue_timeout: 1,
      connection_timeout: 5,
      socket_timeout: 5
    }
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
      connection_timeout: options.connection_timeout.to_i,
      socket_timeout: options.socket_timeout.to_i
    }
  end

  def before
    require 'mongo'
    Mongo::Logger.logger = logger
    return unless safe_to_operate?

    if wired_tiger?
      logger.info "Wired Tiger storage engine detected"
      carefully('stop mongo') { stop_mongo } if options.shutdown
    else
      logger.info "MMAPv1 storage engine detected"
      carefully('lock mongo') { lock_mongo }
    end
  end

  def after
    if wired_tiger?
      carefully('start mongo') { start_mongo } if options.shutdown
    else
      carefully('unlock mongo') { unlock_mongo }
    end

    if carefully('check that mongo is still accessible') { client.command(serverStatus: 1).first }
      logger.info "Received status from mongo, everything appears to be ok"
    end
  end

  def name
    "Mongo"
  end

  private

  def safe_to_operate?
    # we check for strict equality with booleans here, because nil means an
    # error occurred while checking, and it is unsafe to operate
    return true if (primary? == false) or (standalone? == true)
    logger.error "This appears to be a primary member, refusing to operate"
    false
  end

  def wired_tiger?
    if @wired_tiger.nil?
      @wired_tiger = client.command(serverStatus: 1).first.has_key? WIRED_TIGER_KEY
    end
    @wired_tiger
  end

  def primary?
    carefully 'check whether this node is a primary' do
      if @primary.nil?
        @primary = client.command(isMaster: 1).first['ismaster']
      end
      @primary
    end
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
    logger.info "Starting mongodb via 'service #{options[:service]} start'"
    system "service #{options[:service]} start"
  end

  def lock_mongo
    logger.info "Locking mongo"
    client.command(fsync: 1, lock: true)
  end

  def unlock_mongo
    logger.info "Unlocking mongo"
    client.database['$cmd.sys.unlock'].find().read
  end
end