require 'mongo'
WT_STATUS = [{ "#{EasyE::Plugin::MongoPlugin::WIRED_TIGER_KEY}" => { } }]
MMAP_STATUS = [{ }]
describe EasyE::Plugin::MongoPlugin do
  let(:plugin) { EasyE::Plugin::MongoPlugin.new }
  let(:connection) { spy 'Mongo connection' } 
  let(:connection2) { spy 'Mongo connection #2' } 

  context "with authentication enabled" do
    before :each do
      plugin.options.user = 'user'
      plugin.options.password = 'password'
      expect(Mongo::Client).to receive(:new).with("mongodb://localhost:27017", user: 'user', password: 'password').and_return(connection)
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

      context "on mmapv1" do
        before :each do
          expect(connection).to receive(:command).with(serverStatus: 1).and_return(MMAP_STATUS)
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
        end

        context "and shutdown succeeds" do
          before :each do
            expect(connection).to receive(:command).with(shutdown: 1).and_raise(Mongo::Error::SocketError.new 'boom!')
          end

          context "and start up succeeds" do
            before :each do
              expect(Mongo::Client).to receive(:new).and_return(connection2)
              expect(plugin).to receive(:system).with('service mongodb start')
              plugin.before
            end

            after :each do
              plugin.after
            end

            subject { connection2 }
            it { is_expected.to receive(:command).once.with(serverStatus: 1) }
          end
        end
      end
    end
  end
end