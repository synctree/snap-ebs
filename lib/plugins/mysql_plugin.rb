class SnapEbs::Plugin::MysqlPlugin < SnapEbs::Plugin
  def defined_options
    {
      user: 'MySql Username',
      pass: 'MySql Password',
      port: 'MySql port',
      host: 'MySql host'
    }
  end

  def before
    require 'mysql'
    Mysql.new
  end

  def after
  end

  def name
    "Mysql"
  end
end