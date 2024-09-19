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

  test "link should be present" do
    @content.link = ""
    assert_not @content.valid?
  end
end
