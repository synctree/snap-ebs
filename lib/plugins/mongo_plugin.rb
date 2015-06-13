require 'pp'
class EasyE::Plugin::MongoPlugin < EasyE::Plugin
  WIRED_TIGER_KEY = 'wiredTiger'
  attr_accessor :client
  def defined_options
    {
      service: 'Service to start after shutting down server',
      shutdown: 'Shutdown mongodb server (this is required if your data and journal are on different volumes',
      port: 'Mongo port',
      host: 'Mongo host'
    }
  end

  def default_options
    {
      service: 'mongodb',
      port: '27017',
      shutdown: false,
      host: 'localhost'
    }
  end

  def client
    @client ||= Mongo::Client.new "mongodb://#{options.host}:#{options.port}"
  end

  def before
    require 'mongo'
    if wired_tiger?
      logger.info "Wired Tiger storage engine detected"
    else
      logger.info "MMAPv1 storage engine detected"
    end

    shutdown_mongo if wired_tiger? and options.shutdown
  end

  def after
    start_mongo if wired_tiger? and  options.shutdown
  end

  def name
    "Mongo"
  end

  private

  def wired_tiger?
    if @wired_tiger.nil?
      @wired_tiger = client.command(serverStatus: 1).first.has_key? WIRED_TIGER_KEY
    end
    @wired_tiger
  end

  def shutdown_mongo
    logger.info 'Shutting down mongodb'
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
    system "service #{options[:service]} start"
    pp client.command(serverStatus: 1).to_a
  end
end