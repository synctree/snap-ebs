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
      password: nil,
      port: 3306,
      host: 'localhost'
    }
  end

  def before
    require 'mysql2'
    return logger.error "This appears to be a master in a replication set. Refusing to operate." if master?
    stop_mysql
  end

  def after
    return logger.error "This appears to be a master in a replication set. Refusing to operate." if master?
    start_mysql
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
    system("service mysql stop")
  end

  def start_mysql
    system("service mysql start")
  end
end