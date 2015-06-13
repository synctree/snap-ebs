require 'mongo'
describe EasyE::Plugin::MongoPlugin do
  let(:plugin) { EasyE::Plugin::MongoPlugin.new }
  let(:connection) { spy 'Mongo connection' } 

  context "ideally" do
    context "before" do
      before do
        expect(Mongo::Client).to receive(:new).and_return(connection)
        expect(connection).to receive(:command).with(shutdown: 1).and_raise(Mongo::Error::SocketError.new 'boom!')
        expect(plugin).to receive(:system).with('service mongodb start')
        plugin.before
      end

      after do
        plugin.after
      end

      subject { connection }
      it { is_expected.to be }
    end
  end
end