describe EasyE::Plugin do
  before do
    class TestPlugin < EasyE::Plugin
      def self.collect_options option_parser
      end
    end
  end

  let(:easy_e) { EasyE.new }
  context "all registered plugins" do
    before do
      expect(TestPlugin).to receive(:collect_options).with(easy_e.option_parser)
      easy_e.collect_options
    end

    subject { easy_e.registered_plugins }
    it { is_expected.to be_an Array }
    it { is_expected.to include TestPlugin }
  end
end