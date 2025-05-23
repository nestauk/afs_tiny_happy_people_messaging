require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
  end

  test "shows messages received from users" do
    message1 = create(:message, status: "received")
    user = create(:user, first_name: "Bob")
    message2 = create(:message, status: "sent", user:, body: "Hello")

    sign_in

    assert_text message1.user.full_name
    assert_text message1.body

    refute_text message2.user.full_name
    refute_text message2.body
  end

  test "admins can mark messages as seen" do
    message = create(:message, status: "received")

    sign_in

    assert_text message.body

    click_on "Mark as seen"

    assert_text "Message marked as seen"

    assert_no_text message.body
  end
end
