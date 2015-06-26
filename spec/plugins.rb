require './fixture/test'
describe SnapEbs::Plugin do
  let(:snap_ebs) { SnapEbs.new }
  let(:test_plugin) { SnapEbs::Plugin::Test.new }

  context "all registered plugins" do
    subject { snap_ebs.registered_plugins }
    it { is_expected.to be_an Array }
    it { is_expected.to include SnapEbs::Plugin::Test }
  end

  context "all loaded plugins" do
    before do
      expect(SnapEbs::Plugin::Test).to receive(:new).and_call_original
    end

    subject { snap_ebs.plugins }
    it { is_expected.to be_an Array }
    it "include an instance of SnapEbs::Plugin::Test" do
      expect(subject.select { |x| x.kind_of? SnapEbs::Plugin::Test }.length).to be >= 1
    end
  end

  context "collected option parser" do
    before do
      expect_any_instance_of(SnapEbs::Plugin::Test).to receive(:collect_options).and_call_original
      expect_any_instance_of(SnapEbs::Plugin::Test).to receive(:defined_options).and_call_original
      expect(SnapEbs::Plugin::Test).to receive(:new).and_return(test_plugin)
    end

    let(:option_parser) { snap_ebs.option_parser }

    subject { option_parser }
    it { is_expected.to be_an OptionParser }
    it "includes the --test-option option" do
      expect(subject.to_a.select { |x| x[/--test-option/] }).not_to be_empty
    end

    context 'when receiving ["--test", "--test-option", "foo" ]' do
      before(:each) do
        option_parser.parse! ["--test", "--test-option=foo", "foo" ]
      end

      subject { test_plugin.options.option }
      it { is_expected.to eql "foo" }

      context "then run" do
        before do
          expect(test_plugin).to receive(:before).and_call_original
          expect(test_plugin).to receive(:after).and_call_original
          expect(snap_ebs).to receive(:take_snapshots) # and don't call original
        end
        before(:each) { snap_ebs.run }
        subject { test_plugin }
        it { is_expected.to be }
      end
    end
  end

  context "test plugin" do
    context "name" do
      subject { test_plugin.name }
      it { is_expected.to eq 'Test' }
    end
  end
end