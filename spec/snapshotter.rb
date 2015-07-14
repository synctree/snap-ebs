require 'fog'

AWS_INSTANCE_ID_URL_RESPONSE = <<EOS
{
  "instanceId" : "i-7a12445a"
}
EOS

describe SnapEbs::Snapshotter do
  let(:snap_ebs) {
    result = SnapEbs.new
    result.compute = spy 'compute'
    result
  }

  before do
    Fog.mock!
  end

  context "take_snapshots" do
    before() { SnapEbs.logger = spy 'logger' }
    let(:attachedVolume1) { spy('attachedVolume1') }
    let(:attachedVolume2) { spy('attachedVolume2') }
    let(:detachedVolume1) { spy('detachedVolume1') }
    let(:compute_snapshots) { spy('compute.snapshots') }
    let(:snapshot) { spy('snapshot') }
    let(:snapshots_taken) { snap_ebs.take_snapshots }

    before do
      # *consistent* snapshots
      expect(snap_ebs).to receive(:system).once.with('sync')

      # mock instance ID info
      expect(HTTParty).to receive(:get).at_least(:once).with(SnapEbs::Snapshotter::AWS_INSTANCE_ID_URL) { AWS_INSTANCE_ID_URL_RESPONSE }

      # mock volume list
      expect(attachedVolume1).to receive_messages(server_id: "i-7a12445a", id: "vol-00000001")
      expect(attachedVolume2).to receive_messages(server_id: "i-7a12445a", id: "vol-00000002")
      expect(detachedVolume1).to receive_messages(server_id: "i-deadbeef")
      expect(snap_ebs.compute).to receive(:volumes).at_least(:once) do
        [ attachedVolume1, attachedVolume2, detachedVolume1 ]
      end

      # mock snapshot creation
      expect(snap_ebs.compute).to receive(:snapshots).at_least(:once) { compute_snapshots }
      expect(compute_snapshots).to receive(:new).at_least(:once) { snapshot }
      expect(snapshot).to receive("volume_id=").with("vol-00000001")
      expect(snapshot).to receive("volume_id=").with("vol-00000002")
      expect(snapshot).to receive(:save).twice
    end

    context "snapshots_taken" do 
      subject { snapshots_taken }
      it { is_expected.to be_an Array }
    end
  end
end