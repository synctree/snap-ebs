class EasyE::Plugin::Mysql < EasyE::Plugin
  def defined_options
    {
      user: 'MySql Username',
      pass: 'MySql Password',
      port: 'MySql port',
      host: 'MySql host'
    }
  end
end