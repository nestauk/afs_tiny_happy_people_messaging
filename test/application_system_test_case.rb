require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # GitHub Actions runners are shared/slower than local dev, so page renders
  # can occasionally take longer than a local 10s wait allows.
  WAIT_TIMEOUT = ENV["CI"] ? 20 : 10

  Capybara.default_max_wait_time = WAIT_TIMEOUT
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
      timeout: WAIT_TIMEOUT,
    },
  )

  # The failure screenshot isn't uploaded as a CI artifact, so on a slow CI
  # runner it just adds a second Ferrum timeout on top of the real failure.
  def take_failed_screenshot
    super unless ENV["CI"]
  end

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

  def assert_page_is_accessible
    script = <<~JS
      let js = document.createElement("script");
      js.setAttribute("src", arguments[0]);
      js.setAttribute("type", "module");
      
      let callback = arguments[arguments.length-1];
      js.onload = () => {
        axe.configure({
          reporter: "no-passes",
        })
        axe
          .run({runOnly: {type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice']}})
          .then(results => {
            callback(results)
          })
          .catch(err => {
            callback(err)
          });
      }
      
      document.body.appendChild(js);
    JS

    result = evaluate_async_script(script, ViteRuby.instance.manifest.path_for("accessibility_testing.ts"))

    assert result["violations"].length == 0, "Accessibility violations: #{JSON.pretty_generate(result["violations"])}"

    self
  end
end
