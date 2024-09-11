require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
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
    assert_text "Hello, user!"
  end

  private

  def sign_in
    visit new_admin_session_path
    fill_in "Email", with: @admin.email
    fill_in "Password", with: @admin.password
    click_on "Log in"
    assert_text "Signed in successfully."
  end
end
