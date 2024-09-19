require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def sign_in(admin = @admin)
    visit new_admin_session_path
    fill_in "Email", with: @admin.email
    fill_in "Password", with: @admin.password
    click_on "Log in"
    assert_text "Signed in successfully."
  end

  def assert_field_has_errors(label_text)
    find_field(label_text).assert_ancestor(".input.field_with_errors")
  end
end
