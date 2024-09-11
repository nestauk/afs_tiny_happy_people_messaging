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

  private

  def sign_in
    visit new_admin_session_path
    fill_in "Email", with: @admin.email
    fill_in "Password", with: @admin.password
    click_on "Log in"
    assert_text "Signed in successfully."
  end
end
