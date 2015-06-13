class EasyE::Plugin::MongoPlugin < EasyE::Plugin
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
    shutdown_mongo if options.shutdown
  end

  def after
    start_mongo if options.shutdown
  end

  def name
    "Mongo"
  end

  private

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

    done = false
    until done
      begin
        client.command serverStatus: 1
        done = true
      rescue Errno::ECONNREFUSED => e
        logger.info "Unable to connect to mongo (#{e}), retrying shortly"
        sleep 1
      end
    end
  end
end