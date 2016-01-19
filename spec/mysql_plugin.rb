require 'mysql2'

MASTER_PROCESSLIST = [{"Id"=>74, "User"=>"snap_ebs_slave", "Host"=>"slave-mmap:54438", "db"=>nil, "Command"=>"Binlog Dump", "Time"=>22394, "State"=>"Master has sent all binlog to slave; waiting for binlog to be updated", "Info"=>nil}, {"Id"=>86, "User"=>"root", "Host"=>"localhost", "db"=>nil, "Command"=>"Query", "Time"=>0, "State"=>nil, "Info"=>"SHOW PROCESSLIST"}]
SLAVE_PROCESSLIST = [{"Id"=>79, "User"=>"snap_ebs", "Host"=>"localhost", "db"=>nil, "Command"=>"Query", "Time"=>0, "State"=>nil, "Info"=>"SHOW PROCESSLIST"}]
SLAVE_SLAVE_STATUS = [{"Slave_IO_State"=>"Waiting for master to send event", "Master_Host"=>"master", "Master_User"=>"easy_e_slave", "Master_Port"=>3306, "Connect_Retry"=>60, "Master_Log_File"=>"mysql-bin.000005", "Read_Master_Log_Pos"=>107, "Relay_Log_File"=>"relay-bin.000008", "Relay_Log_Pos"=>253, "Relay_Master_Log_File"=>"mysql-bin.000005", "Slave_IO_Running"=>"Yes", "Slave_SQL_Running"=>"Yes", "Replicate_Do_DB"=>"", "Replicate_Ignore_DB"=>"", "Replicate_Do_Table"=>"", "Replicate_Ignore_Table"=>"", "Replicate_Wild_Do_Table"=>"", "Replicate_Wild_Ignore_Table"=>"", "Last_Errno"=>0, "Last_Error"=>"", "Skip_Counter"=>0, "Exec_Master_Log_Pos"=>107, "Relay_Log_Space"=>549, "Until_Condition"=>"None", "Until_Log_File"=>"", "Until_Log_Pos"=>0, "Master_SSL_Allowed"=>"No", "Master_SSL_CA_File"=>"", "Master_SSL_CA_Path"=>"", "Master_SSL_Cert"=>"", "Master_SSL_Cipher"=>"", "Master_SSL_Key"=>"", "Seconds_Behind_Master"=>0, "Master_SSL_Verify_Server_Cert"=>"No", "Last_IO_Errno"=>0, "Last_IO_Error"=>"", "Last_SQL_Errno"=>0, "Last_SQL_Error"=>"", "Replicate_Ignore_Server_Ids"=>"", "Master_Server_Id"=>3932962415}]
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
      subject { plugin }
      it "locks and unlocks tables" do
        # expect(client).to receive(:query)
        #   .with('SHOW SLAVE STATUS')
        #   .and_return(SLAVE_SLAVE_STATUS)

        expect(client).to receive(:query)
          .with('FLUSH LOCAL TABLES')
          .and_return(nil)

        expect(client).to receive(:query)
          .with('FLUSH LOCAL TABLES WITH READ LOCK')
          .and_return(nil)

        expect(client).to receive(:query)
          .with('UNLOCK TABLES')
          .and_return(nil)

        expect(subject.before).to be true
        expect(subject.after).to be true
      end
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