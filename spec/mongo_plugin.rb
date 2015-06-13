require 'mongo'
describe EasyE::Plugin::MongoPlugin do
  let(:plugin) { EasyE::Plugin::MongoPlugin.new }
  let(:connection) { spy 'Mongo connection' } 

  context "ideally" do
    context "before" do
      before do
        expect(Mongo::Client).to receive(:new).and_return(connection)
        plugin.before
      end
      subject { connection }
      it { is_expected.to be }
    end
  end
end