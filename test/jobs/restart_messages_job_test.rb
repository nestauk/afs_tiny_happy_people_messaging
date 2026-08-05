require "test_helper"

class RestartMessagesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform updates user and sends message" do
    user = create(:user, contactable: false)

    User.any_instance.stubs(:generate_token_for).returns("123")

    RestartMessagesJob.new.perform(user)

    assert_equal 1, Message.count
    assert_nil user.reload.restart_at
    assert_equal false, user.contactable
    assert Message.last.body.include?(edit_user_url(user, token: "123"))
  end

  test "#perform sends restart message in user's preferred language" do
    create(:group, language: "cy")
    user = create(:user, contactable: false, language: "cy")
    User.any_instance.stubs(:generate_token_for).returns("123")

    RestartMessagesJob.new.perform(user)

    assert_equal 1, Message.count
    assert_nil user.reload.restart_at
    assert_equal false, user.contactable
    assert Message.last.body.include?(edit_user_url(user, token: "123"))
    assert Message.last.body.include?("Mae'r aros drosodd o'r diwedd!")
  end
end
