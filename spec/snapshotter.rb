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
    let(:attachedVolume1) { spy('attachedVolume1') }
    let(:attachedVolume2) { spy('attachedVolume2') }
    let(:detachedVolume1) { spy('detachedVolume1') }
    let(:snapshots_taken) { easy_e.take_snapshots }
    before do
      expect(HTTParty).to receive(:get).at_least(:once).with(EasyE::Snapshotter::AWS_INSTANCE_ID_URL) { AWS_INSTANCE_ID_URL_RESPONSE }
      expect(attachedVolume1).to receive(:server_id) { "i-7a12445a" }
      expect(attachedVolume2).to receive(:server_id) { "i-7a12445a" }
      expect(detachedVolume1).to receive(:server_id) { "i-deadbeef" }
      expect(easy_e.compute).to receive(:volumes).at_least(:once) do
        [ attachedVolume1, attachedVolume2, detachedVolume1 ]
      end
    end

    context "snapshots_taken" do 
      subject { snapshots_taken }
      it { is_expected.to be_a Hash }
    end
  end
end