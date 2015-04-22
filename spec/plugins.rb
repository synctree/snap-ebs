describe EasyE::Plugin do
  let(:easy_e) { EasyE.new }

  context "on startup" do
    context "loaded plugins" do
      before do
        class TestClass < EasyE::Plugin
        end
      end

      subject { easy_e.plugins }
      it { is_expected.to be_an Array }
      it { is_expected.to include TestClass }
    end
  end
end