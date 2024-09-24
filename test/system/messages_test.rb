require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @admin = create(:admin)
    @user = create(:user)
  end

  test "sending a message to a user" do
    sign_in

    visit users_path
    click_on "#{@user.first_name} #{@user.last_name}"

    click_on "Send message"
    fill_in "Body", with: "Hello, user!"

    stub_successful_twilio_call("Hello, user!", @user)
    click_on "Send message"

    assert_text "Message sent!"
    
    perform_enqueued_jobs

    visit user_path(@user)

    assert_text "Hello, user!"
    assert_text "Delivered"
  end

  test "shows as failed if message did not send" do
    sign_in

    visit users_path
    click_on "#{@user.first_name} #{@user.last_name}"

    click_on "Send message"
    fill_in "Body", with: "Hello, user!"

    stub_unsuccessful_twilio_call("Hello, user!", @user)
    click_on "Send message"
    
    assert_text "Message sent!"
    
    perform_enqueued_jobs

    visit user_path(@user)

    assert_text "Hello, user!"
    assert_text "Failed"
  end

  test "can track whether a user has clicked on the link" do
    content = create(:content, link: root_path)
    message = create(:message, user: @user, content: content)

    visit next_user_messages_path(@user)

    assert_equal true, message.reload.clicked_on
  end
end
