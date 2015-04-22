require 'fog'

describe EasyE::Snapshotter do
  let(:easy_e) {
    result = EasyE.new
    result.compute = spy 'compute'
    result
  }

  before do
    Fog.mock!
  end

  context "take_snapshots" do
    before do       
      easy_e.take_snapshots
    end

    context "snapshots_taken" do 
      let(:snapshots_taken) { easy_e.take_snapshots }
      subject { snapshots_taken }
      it { is_expected.to be_a Hash }
    end

    context "compute" do 
      subject { easy_e.compute }
      it { is_expected.to have_received(:servers)}
      it { is_expected.to have_received(:volumes)}
    end
  end
end