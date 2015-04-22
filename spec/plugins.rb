describe EasyE::Plugin do
  before do
    class TestPlugin < EasyE::Plugin
      def self.collect_options option_parser
        option_parser.on nil, '--test', 'Enables the test plugin'
      end
    end
  end

  let(:easy_e) { EasyE.new }
  context "all registered plugins" do
    subject { easy_e.registered_plugins }
    it { is_expected.to be_an Array }
    it { is_expected.to include TestPlugin }
  end

  context "collected options" do
    before do
      expect(TestPlugin).to receive(:collect_options)
    end
    subject { easy_e.option_parser }
    it { is_expected.to be_an OptionParser }
  end
end