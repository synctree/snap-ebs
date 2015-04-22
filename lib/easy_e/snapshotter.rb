module EasyE::Snapshotter
  attr_writer :storage, :compute
  def take_snapshots
    compute.servers
    storage.volumes
    { foo: 'bar' }
  end

  def storage
    unless @storage
      @storage =Fog::Storage.new({
        :aws_access_key_id => "asdf",
        :aws_secret_access_key => "asdf",
        :provider => "AWS"
      }) 
    end

    @storage
  end

  def compute
    unless @compute
      @compute = Fog::Compute.new({
        :aws_access_key_id => "asdf",
        :aws_secret_access_key => "asdf",
        :provider => "AWS"
      }) 
    end

    @compute
  end
end