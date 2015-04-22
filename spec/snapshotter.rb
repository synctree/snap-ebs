require 'fog'

AWS_INSTANCE_ID_URL_RESPONSE = <<EOS
{
  "instanceId" : "i-7a12445a"
}
EOS

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
      expect(HTTParty).to receive(:get).at_least(:once).with(EasyE::Snapshotter::AWS_INSTANCE_ID_URL) { AWS_INSTANCE_ID_URL_RESPONSE }
      easy_e.take_snapshots
    end

    context "snapshots_taken" do 
      let(:snapshots_taken) { easy_e.take_snapshots }
      subject { snapshots_taken }
      it { is_expected.to be_a Hash }
    end

    context "compute" do 
      subject { easy_e.compute }
      it { is_expected.to have_received(:volumes)}
    end
  end
end