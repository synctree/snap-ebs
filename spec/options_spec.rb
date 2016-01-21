require 'optparse'
describe SnapEbs::Options do
  let(:snap_ebs) { SnapEbs.new }

  context "startup" do 
    subject { snap_ebs.option_parser }
    it { is_expected.to be_an OptionParser }
    it { is_expected.to be snap_ebs.option_parser }
  end
end