require 'mongo'
WT_STATUS = [{ "#{SnapEbs::Plugin::MongoPlugin::WIRED_TIGER_KEY}" => { } }]
MMAP_STATUS = [{ }]
FSYNC_LOCK_SUCCESS_RESULT = [{
  "info" => "now locked against writes, use db.fsyncUnlock() to unlock",
  "seeAlso" => "http://dochub.mongodb.org/core/fsynccommand",
  "ok" => 1
}]

FSYNC_UNLOCK_SUCCESS_RESULT = { "ok" => 1, "info" => "unlock completed" }

IS_MASTER_PRIMARY_RESULT = [{
  "setName" => "snap-ebs",
  "setVersion" => 3,
  "ismaster" => true,
  "secondary" => false,
  "primary" => "slave-mmap=>2700",
  "me" => "slave-mmap=>2700"
}]

IS_MASTER_SECONDARY_RESULT = [{
  "setName" => "snap-ebs",
  "setVersion" => 3,
  "ismaster" => false,
  "secondary" => true,
  "primary" => "slave-wt=>2700",
  "me" => "slave-mmap=>2700",
  "ok" => 1
}]

describe SnapEbs::Plugin::MongoPlugin do
  before() { SnapEbs.logger = spy 'logger' }
  let(:plugin) { SnapEbs::Plugin::MongoPlugin.new }
  let(:connection) { spy 'Mongo connection' } 
  let(:connection2) { spy 'Mongo connection #2' } 

  context "when --mongo-command is set" do
    before :each do
      plugin.options.command = 'foo bar'
      expect(plugin).to receive(:system).with('foo bar')

      # send ignores method visibility
      plugin.send :start_mongo
    end
    subject { plugin }
    it { is_expected.to be }
  end

  context "when connection times out" do
    before :each do
      expect(Mongo::Client).to receive(:new).and_raise(Mongo::Error::NoServerAvailable, "nobody's home!").at_least(1)
      plugin.before
    end

    subject { plugin }
    it { is_expected.to be}
  end

  context "with authentication enabled" do
    before :each do
      plugin.options.user = 'user'
      plugin.options.password = 'password'
      expect(Mongo::Client).to receive(:new).with(["localhost:27017"], connect: :direct, user: 'user', password: 'password', server_selection_timeout: 30, wait_queue_timeout: 1, connect_timeout: 5, socket_timeout: 5).and_return(connection)
      expect(plugin).to receive(:primary?).and_return(false)
      plugin.before
    end

    subject { plugin }
    it { is_expected.to be }
  end

  context "when connection succeeds" do
    before :each do
      expect(Mongo::Client).to receive(:new).and_return(connection)
    end

    context "with --mongo-shutdown enabled" do
      before :each do
        plugin.options.shutdown = true
      end

      context "on a primary server" do
        before :each do
          expect(connection).not_to receive(:command).with(fsync: 1, lock: true)
          expect(connection).to receive(:command).once.with(isMaster: 1).and_return(IS_MASTER_PRIMARY_RESULT)
          expect(plugin).to receive(:system).with('service mongod start').and_return(true).once
          plugin.before
        end

        after :each do
          plugin.after
        end

        subject { connection }
        it { is_expected.not_to receive(:command).with(fsync: 1, lock: true) }
      end

      context "on mmapv1" do
        let(:cmd_sys_unlock) { spy('$cmd.sys.unlock') }
        let(:result) { spy 'mongo result' }
        before :each do
          expect(connection).to receive(:command).at_least(1).with(serverStatus: 1).and_return(MMAP_STATUS)
          expect(connection).to receive(:command).once.with(fsync: 1, lock: true).and_return(FSYNC_LOCK_SUCCESS_RESULT)
          expect(connection).to receive(:command).once.with(isMaster: 1).and_return(IS_MASTER_SECONDARY_RESULT)
          expect(connection).to receive(:[]).with('$cmd.sys.unlock').and_return(cmd_sys_unlock)
          expect(cmd_sys_unlock).to receive(:find).once.and_return(result)
          expect(result).to receive(:read).and_return(FSYNC_UNLOCK_SUCCESS_RESULT)
          expect(connection).not_to receive(:command).with(shutdown: 1)
          plugin.before
        end

        after :each do
          plugin.after
        end

        subject { connection }
        it { is_expected.to be }
      end

      context "on wired tiger" do
        before :each do
          expect(connection).to receive(:command).with(serverStatus: 1).and_return(WT_STATUS)
          expect(connection).to receive(:command).once.with(isMaster: 1).and_return(IS_MASTER_SECONDARY_RESULT)
        end

        context "and shutdown succeeds" do
          before :each do
            expect(connection).to receive(:command).with(shutdown: 1).and_raise(Mongo::Error::SocketError.new 'boom!')
          end

          context "and start up succeeds" do
            before :each do
              expect(Mongo::Client).to receive(:new).and_return(connection2)
              expect(plugin).to receive(:system).with('service mongod start').and_return(true).once
              plugin.before
            end

            after :each do
              plugin.after
            end

            subject { connection2 }
            it { is_expected.to receive(:command).once.with(serverStatus: 1) }
          end

          context "and start up fails" do
            before :each do
              plugin.options.retry = 1
              plugin.options.interval = 0
              expect(Mongo::Client).to receive(:new).and_return(connection2)
              expect(plugin).to receive(:system).with('service mongod start').and_return(false).exactly(2)
              plugin.before
            end

            after :each do
              plugin.after
            end

            subject { connection2 }
            it { is_expected.to receive(:command).with(serverStatus: 1) }
          end
        end
      end
    end
  end
end