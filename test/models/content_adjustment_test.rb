require "test_helper"

class ContentAdjustmentTest < ActiveSupport::TestCase
  def setup
    @subject = create(:content_adjustment)
  end

  test "should be valid" do
    assert @subject.valid?
  end
end
