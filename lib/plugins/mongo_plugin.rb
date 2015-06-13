class EasyE::Plugin::MongoPlugin < EasyE::Plugin
  attr_accessor :client
  def defined_options
    {
      service: 'Service to start after shutting down server',
      port: 'Mongo port',
      host: 'Mongo host'
    }
  end

  def default_options
    {
      service: 'mongodb',
      port: '27017',
      host: 'localhost'
    }
  end

  def client
    @client ||= Mongo::Client.new "mongodb://#{options.host}:#{options.port}"
  end

  def before
    require 'mongo'
    logger.info 'Shutting down mongodb'
    begin
      # this will always raise an exception after it completes
      client.command shutdown: 1
    rescue Mongo::Error::SocketError => e
      logger.debug "Received expected socket error"
    end

    # we need a new connection now since the server has shut down
    @client = nil
  end

  def after
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

  def name
    "Mongo"
  end
end