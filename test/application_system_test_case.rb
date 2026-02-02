require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.default_max_wait_time = 10
  Capybara.disable_animation = true
  Capybara.javascript_driver = :cuprite
  driven_by(
    :cuprite,
    options: {
      window_size: [1200, 800],
      headless: true,
      browser_options: {
        "no-sandbox": nil,
      },
      timeout: 10,
    },
  )

  def sign_in(admin = @admin)
    token = @admin.encode_passwordless_token(expires_at: 2.hours.from_now)

    visit admin_magic_link_url(
      admin: {
        email: @admin.email,
        token:,
      },
    )

    assert_text "success"
  end
end
