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

  test "destroy does not delete associated messages" do
    create(:message, content: @content)

    assert_raises ActiveRecord::DeleteRestrictionError do
      @content.destroy
    end
  end

  test ".active" do
    assert_includes Content.active, @content

    @content.update(archived_at: Time.now)
    assert_not_includes Content.active, @content
  end

  test "#archived?" do
    assert_not @content.archived?

    @content.archived_at = Time.now
    assert @content.archived?
  end
end
