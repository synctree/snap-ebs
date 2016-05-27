class SnapEbs::Plugin::Test < SnapEbs::Plugin
  def defined_options
    { option: 'test option' }
  end

  def before
    true
  end

  def after
    true
  end

  def name
    "Test"
  end
end
