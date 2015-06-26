class SnapEbs::Plugin::Test < SnapEbs::Plugin
  def defined_options
    { option: 'test option' }
  end

  def before
  end

  def after
  end

  def name
    "Test"
  end
end
