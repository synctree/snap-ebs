require 'mysql'
describe EasyE::Plugin::MysqlPlugin do
  let(:plugin) { EasyE::Plugin::MysqlPlugin.new }
  let(:connection) { spy 'Mysql connection' } 

  context "ideally" do
    context "before" do
      before do
        expect(Mysql).to receive(:new).and_return(connection)
        plugin.before
      end
      subject { connection }
      it { is_expected.to be }
    end
  end
end