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
      snap_ebs.options[:directory] = '/foo,/bar'
      # *consistent* snapshots
      expect(snap_ebs).to receive(:system).once.with('sync')

      # mock instance ID info
      expect(HTTParty).to receive(:get).at_least(:once).with(SnapEbs::Snapshotter::AWS_INSTANCE_ID_URL) { AWS_INSTANCE_ID_URL_RESPONSE }

      # mock volume list
      expect(attachedVolume1).to receive_messages(server_id: "i-7a12445a", id: "vol-00000001", device: "/dev/sdy")
      expect(attachedVolume2).to receive_messages(server_id: "i-7a12445a", id: "vol-00000002", device: "/dev/sdz")
      allow(detachedVolume1).to receive_messages(server_id: nil,          id: "vol-00000003")

      # mock device mapping
      expect(snap_ebs).to receive(:directory_to_device).at_least(:once).with('/').and_return('/dev/xvdy')
      expect(snap_ebs).to receive(:directory_to_device).at_least(:once).with('/foo').and_return('/dev/xvdy')
      expect(snap_ebs).to receive(:directory_to_device).at_least(:once).with('/bar').and_return('/dev/xvdz')

      # mock device mapping
      allow(snap_ebs).to receive(:device_to_directory).with('/dev/xvdy').and_return('/foo')
      expect(snap_ebs).to receive(:device_to_directory).with('/dev/xvdz').and_return('/bar')

      expect(snap_ebs.compute).to receive(:volumes).at_least(:once) do
        [ attachedVolume1, attachedVolume2, detachedVolume1 ]
      end

      # mock snapshot creation
      expect(snap_ebs.compute).to receive(:snapshots).at_least(:once) { compute_snapshots }
      expect(compute_snapshots).to receive(:new).twice { snapshot }
      expect(snapshot).to receive("volume_id=").with("vol-00000001")
      expect(snapshot).to receive("volume_id=").with("vol-00000002")
      expect(snapshot).to receive(:save).twice
    end

    context "with --fs-freeze" do 
      before do
        snap_ebs.options[:fs_freeze] = true
        expect(snap_ebs).to receive(:system).with("which fsfreeze > /dev/null").and_return true
        expect(snap_ebs).not_to receive(:system).with("fsfreeze -f /foo")
        expect(snap_ebs).to receive(:system).with("fsfreeze -f /bar")
        expect(snap_ebs).not_to receive(:system).with("fsfreeze -u /foo")
        expect(snap_ebs).to receive(:system).with("fsfreeze -u /bar")
      end

      subject { snapshots_taken }
      it { is_expected.to be_an Array }
    end
  end
end