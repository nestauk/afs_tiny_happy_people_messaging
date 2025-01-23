require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def sign_in(admin = @admin)
    token = @admin.encode_passwordless_token(expires_at: 2.hours.from_now)

    visit admin_magic_link_url(
      admin: {
        email: @admin.email,
        token:
      }
    )

    assert_text "success"
  end

  def assert_field_has_errors(label_text)
    find_field(label_text).assert_ancestor(".input.field_with_errors")
  end
end
