require 'mongo'
describe EasyE::Plugin::MongoPlugin do
  let(:plugin) { EasyE::Plugin::MongoPlugin.new }
  let(:connection) { spy 'Mongo connection' } 
  let(:connection2) { spy 'Mongo connection #2' } 

  context "with --mongo-shutdown enabled" do
    before :each do
      plugin.options.shutdown = true
    end

    context "when connection succeeds" do
      before :each do
        expect(Mongo::Client).to receive(:new).and_return(connection)
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
          it do
            is_expected.to receive(:command).once.with(serverStatus: 1).and_raise Errno::ECONNREFUSED.new('no mongo here!')
            is_expected.to receive(:command).once.with(serverStatus: 1)
          end
        end
      end
    end
  end
end