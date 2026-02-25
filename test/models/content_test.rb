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

  test "link should be valid URL" do
    content = Content.new(link: "invalid_url")
    content.save
    assert_error(:link, "is not a valid URL. Please check the link and try again.", subject: content)

    stub_request(:any, /notrealdomain.com/).to_return(status: 404)
    content = Content.new(link: "https://notrealdomain.com")
    content.save
    assert_error(:link, "is not valid or does not return a 200 status code. Please check the link and try again.", subject: content)
  end

  test "destroy does not delete associated messages" do
    create(:message, content: @content)

    assert_raises ActiveRecord::DeleteRestrictionError do
      @content.destroy
    end
  end

  test ".active" do
    assert_includes Content.active, @content

    @content.update(archived_at: Time.zone.now)
    assert_not_includes Content.active, @content
  end

  test "#archived?" do
    assert_not @content.archived?

    @content.archived_at = Time.zone.now
    assert @content.archived?
  end
end
