class EasyE::Plugin::Mysql < EasyE::Plugin
  def self.collect_options option_parser
    option_parser.on nil, '--mysql', 'Enables the MySql plugin'
    option_parser
  end
end