describe EasyE::Plugin do
  let(:easy_e) { EasyE.new }

  context "on startup" do
    context "loaded plugins" do
      subject { easy_e.plugins }
      it { is_expected.to be_an Array }
    end
  end
end