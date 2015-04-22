describe EasyE::Plugin do
  before do
    class TestPlugin < EasyE::Plugin
      def defined_options
        { test: 'test option' }
      end
    end
  end

  let(:easy_e) { EasyE.new }
  context "all registered plugins" do
    subject { easy_e.registered_plugins }
    it { is_expected.to be_an Array }
    it { is_expected.to include TestPlugin }
  end

  context "all loaded plugins" do
    before do
      expect(TestPlugin).to receive(:new).and_call_original
    end

    subject { easy_e.plugins }
    it { is_expected.to be_an Array }
    it "include an instance of TestPlugin" do
      expect(subject.select { |x| x.kind_of? TestPlugin }.length).to be >= 1
    end
  end

  context "collected option parser" do
    before do
      expect_any_instance_of(TestPlugin).to receive(:collect_options).and_call_original
      expect_any_instance_of(TestPlugin).to receive(:defined_options).and_call_original
    end

    subject { easy_e.option_parser }
    it { is_expected.to be_an OptionParser }
    it "includes the --test option" do
      expect(subject.to_a.select { |x| x[/--test/] }).not_to be_empty
    end
  end
end