require 'optparse'
describe EasyE::Options do
  let(:easy_e) { EasyE.new }

  context "startup" do 
    subject { easy_e.option_parser }
    it { is_expected.to be_an OptionParser }
  end
end