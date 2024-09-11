require "test_helper"

class ContentTest < ActiveSupport::TestCase
  def setup
    @content = create(:content)
  end

  test "should be valid" do
    assert @content.valid?
  end

  test "body should be present" do
    @content.body = ""
    assert_not @content.valid?
  end

  test "upper_age should be present" do
    @content.upper_age = nil
    assert_not @content.valid?
  end

  test "lower_age should be present" do
    @content.lower_age = nil
    assert_not @content.valid?
  end
end
