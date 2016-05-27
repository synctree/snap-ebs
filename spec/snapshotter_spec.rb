require 'fog'

AWS_INSTANCE_ID_URL_RESPONSE = <<EOS
{
  "instanceId" : "i-7a12445a"
}
EOS

MOCK_DEVICE_MAPPING = {
  '/' => '/dev/xvdy',
  '/foo' => '/dev/xvdy',
  '/bar' => '/dev/xvdz',
}

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
    before(:each) { SnapEbs.logger = logger }
    let(:attachedVolume1) { spy('attachedVolume1') }
    let(:attachedVolume2) { spy('attachedVolume2') }
    let(:compute_snapshots) { spy('compute.snapshots') }
    let(:detachedVolume1) { spy('detachedVolume1') }
    let(:logger) { spy 'logger' }
    let(:snapshot) { spy('snapshot') }
    let(:snapshots_taken) { snap_ebs.take_snapshots }

    before :each do
      snap_ebs.options[:directory] = '/foo,/bar'
      # *consistent* snapshots
      expect(snap_ebs).to receive(:system).once.with('sync')

      # mock instance ID info
      expect(HTTParty).to receive(:get).at_least(:once).with(SnapEbs::Snapshotter::AWS_INSTANCE_ID_URL) { AWS_INSTANCE_ID_URL_RESPONSE }

      MOCK_DEVICE_MAPPING.each do |dir,dev|
        allow(snap_ebs).to receive(:`).at_least(:once).with("df -T #{dir} | grep dev").and_return(dev)
      end

      MOCK_DEVICE_MAPPING.each do |dir,dev|
        allow(snap_ebs).to receive(:`).with("cat /etc/mtab | grep #{dev}").and_return("#{dev} #{dir} foo bar baz bim")
      end
    end

    context "with --fs-freeze" do 
      before do
        snap_ebs.options[:fs_freeze] = true

        # mock volume attachment lookup
        expect(snap_ebs.compute).to receive(:volumes).at_least(:once) do
          [ attachedVolume1, attachedVolume2, detachedVolume1 ]
        end

        # mock volume list
        expect(attachedVolume1).to receive_messages(server_id: "i-7a12445a", id: "vol-00000001", device: "/dev/sdy")
        expect(attachedVolume2).to receive_messages(server_id: "i-7a12445a", id: "vol-00000002", device: "/dev/sdz")
        allow(detachedVolume1).to receive_messages(server_id: nil,          id: "vol-00000003")

        # mock snapshot creation
        expect(snap_ebs.compute).to receive(:snapshots).at_least(:once) { compute_snapshots }
        expect(compute_snapshots).to receive(:new).twice { snapshot }
        expect(snapshot).to receive("volume_id=").with("vol-00000001")
        expect(snapshot).to receive("volume_id=").with("vol-00000002")
        expect(snapshot).to receive(:save).twice

        # mock freeze commands
        expect(snap_ebs).to receive(:system).with("which fsfreeze > /dev/null").and_return true
        expect(snap_ebs).not_to receive(:system).with("fsfreeze -f /foo")
        expect(snap_ebs).to receive(:system).with("fsfreeze -f /bar")
        expect(snap_ebs).not_to receive(:system).with("fsfreeze -u /foo")
        expect(snap_ebs).to receive(:system).with("fsfreeze -u /bar")
      end

      subject { snapshots_taken }
      it { is_expected.to be_an Array }
    end

    context "when AWS fails" do 
      context "with a fog aws error" do
        before :each do
          snap_ebs.options.retry_count = 1
          snap_ebs.options.retry_interval = 0
        end

        context "while listing volumes" do
          before do
            expect(snap_ebs.compute).to receive(:volumes).at_least(:once).and_raise(Fog::Compute::AWS::Error.new("AWS error"))
          end

          subject { snapshots_taken }
          it { is_expected.to be_an Array }
        end

        context "while snapshotting" do
          before(:each) do
            # mock volume attachment lookup
            expect(snap_ebs.compute).to receive(:volumes).at_least(:once) do
              [ attachedVolume1, attachedVolume2, detachedVolume1 ]
            end

            # mock volume list
            expect(attachedVolume1).to receive_messages(server_id: "i-7a12445a", id: "vol-00000001", device: "/dev/sdy")
            expect(attachedVolume2).to receive_messages(server_id: "i-7a12445a", id: "vol-00000002", device: "/dev/sdz")
            allow(detachedVolume1).to receive_messages(server_id: nil,          id: "vol-00000003")

            # mock snapshot creation
            expect(snap_ebs.compute).to receive(:snapshots).at_least(:once) { compute_snapshots }
            expect(compute_snapshots).to receive(:new).twice { snapshot }
            expect(snapshot).to receive("volume_id=").with("vol-00000001")
            expect(snapshot).to receive("volume_id=").with("vol-00000002")

            # mock save errors
            expect(snapshot).to receive(:save).and_raise(Fog::Compute::AWS::Error.new("AWS error")).exactly(4)
            expect(logger).to receive(:warn).at_least(:once)
          end

          subject { snapshots_taken }
          it { is_expected.to be_an Array }
        end
      end
    end
  end
end