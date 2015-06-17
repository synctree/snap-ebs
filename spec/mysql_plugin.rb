require 'mysql2'

MASTER_PROCESSLIST = [{"Id"=>74, "User"=>"snap_ebs_slave", "Host"=>"slave-mmap:54438", "db"=>nil, "Command"=>"Binlog Dump", "Time"=>22394, "State"=>"Master has sent all binlog to slave; waiting for binlog to be updated", "Info"=>nil}, {"Id"=>86, "User"=>"root", "Host"=>"localhost", "db"=>nil, "Command"=>"Query", "Time"=>0, "State"=>nil, "Info"=>"SHOW PROCESSLIST"}]
SLAVE_PROCESSLIST = [{"Id"=>79, "User"=>"snap_ebs", "Host"=>"localhost", "db"=>nil, "Command"=>"Query", "Time"=>0, "State"=>nil, "Info"=>"SHOW PROCESSLIST"}]
describe SnapEbs::Plugin::MysqlPlugin do
  let(:plugin) { SnapEbs::Plugin::MysqlPlugin.new }
  let(:client) { double 'Mysql client' } 
  before :each do
    SnapEbs.logger = ::Logger.new(false)
    expect(Mysql2::Client).to receive(:new)
      .with(host: 'localhost', username: 'root', password: 'root', port: 3306)
      .and_return(client)
  end

  describe 'on a slave' do
    before :each do
      expect(client).to receive(:query)
        .with('SHOW PROCESSLIST')
        .and_return(SLAVE_PROCESSLIST)
    end

    describe 'ideally' do
      before :each do
        expect(client).to receive(:query)
          .with('FLUSH LOCAL TABLES')
          .and_return(nil)

        expect(client).to receive(:query)
          .with('FLUSH LOCAL TABLES WITH READ LOCK')
          .and_return(nil)

        expect(client).to receive(:query)
          .with('UNLOCK TABLES')
          .and_return(nil)
      end

      subject { plugin.before }
      it { is_expected.to be }
    end
  end

  describe 'on a master' do
    before :each do
      expect(client).to receive(:query)
        .with('SHOW PROCESSLIST')
        .and_return(MASTER_PROCESSLIST)

      expect(client).not_to receive(:query)
        .with('FLUSH LOCAL TABLES WITH READ LOCK')
    end

    subject { plugin.before }
    it { is_expected.not_to be }
  end
end