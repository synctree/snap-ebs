class SnapEbs::Plugin::MysqlPlugin < SnapEbs::Plugin
  def defined_options
    {
      shutdown: 'MySQL will only be shut down when this is set to "yes"',
      username: 'MySQL Username',
      password: 'MySQL Password',
      port: 'MySQL port',
      host: 'MySQL host'
    }
  end

  def default_options
    {
      shutdown: 'no',
      username: 'root',
      password: 'root',
      port: 3306,
      host: 'localhost'
    }
  end

  def before
    require 'mysql2'
    if master?
      logger.error "This appears to be a master in a replication set. Refusing to operate."
      return false
    end
    lock_tables
    stop_mysql if options.shutdown == 'yes'
    true
  end

  def after
    if master?
      logger.error "This appears to be a master in a replication set. Refusing to operate."
      return false
    end
    true
  ensure
    unlock_tables
    start_mysql if options.shutdown == 'yes'
  end

  def name
    "Mysql"
  end

  def client
    @client ||= Mysql2::Client.new host: options.host, username: options.username, password: options.password, port: options.port
  end

  private

  def slave?
    if @slave == nil
      @slave = logger.debug client.query("SHOW SLAVE STATUS").to_a.any?
    end
    @slave 
  end

  def lock_tables
    client.query("FLUSH LOCAL TABLES")
    client.query("FLUSH LOCAL TABLES WITH READ LOCK")
  end

  def unlock_tables
    client.query("UNLOCK TABLES")
  end

  # > If you see no Binlog Dump threads on a master server, this means that
  # > replication is not running—that is, that no slaves are currently
  # > connected.
  #
  # https://dev.mysql.com/doc/refman/5.1/en/master-thread-states.html
  def master?
    if @master == nil
      @master = client.query("SHOW PROCESSLIST").to_a.map { |x| x['Command'] }.include? 'Binlog Dump'
    end

    @master
  end

  def stop_mysql
    # TODO
    system("service mysql stop")
  end

  def start_mysql
    # TODO
    system("service mysql start")
  end
end