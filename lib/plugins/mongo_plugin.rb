class EasyE::Plugin::MongoPlugin < EasyE::Plugin
  attr_accessor :client
  def defined_options
    {
      service: 'Service to start after shutting down server',
      port: 'Mongo port',
      host: 'Mongo host'
    }
  end

  def before
    require 'mongo'
    client = Mongo::Client.new "mongodb://#{options.host}:#{options.port}"
    cmd = { }
    cmd[:shutdown] = 1
    logger.debug 'running command'
    logger.debug cmd
    client.command cmd
  end

  def after
    `service #{options[:service]} start`
  end

  def name
    "Mongo"
  end
end