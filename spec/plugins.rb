require './fixture/test'
describe EasyE::Plugin do
  let(:easy_e) { EasyE.new }
  context "all registered plugins" do
    subject { easy_e.registered_plugins }
    it { is_expected.to be_an Array }
    it { is_expected.to include EasyE::Plugin::Test }
  end

  context "all loaded plugins" do
    before do
      expect(EasyE::Plugin::Test).to receive(:new).and_call_original
    end

    subject { easy_e.plugins }
    it { is_expected.to be_an Array }
    it "include an instance of EasyE::Plugin::Test" do
      expect(subject.select { |x| x.kind_of? EasyE::Plugin::Test }.length).to be >= 1
    end
  end

  context "collected option parser" do
    before do
      expect_any_instance_of(EasyE::Plugin::Test).to receive(:collect_options).and_call_original
      expect_any_instance_of(EasyE::Plugin::Test).to receive(:defined_options).and_call_original
    end

    subject { easy_e.option_parser }
    it { is_expected.to be_an OptionParser }
    it "includes the --test-option option" do
      expect(subject.to_a.select { |x| x[/--test-option/] }).not_to be_empty
    end
  end

  context "test plugin" do
    let(:test_plugin) { EasyE::Plugin::Test.new }

    context "name" do
      subject { test_plugin.name }
      it { is_expected.to eq 'Test' }
    end
  end
end