# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src :self, :https, :data
    policy.img_src :self, :https, :data
    policy.object_src :none
    policy.script_src :self,
      :https,
      "https://cc.cdn.civiccomputing.com"
    policy.style_src :self,
      "https://apikeys.civiccomputing.com",
      :unsafe_inline

    if Rails.env.development?
      # Vite requires connect_src for Hot Module Replacement
      policy.connect_src :self, :https, "http://localhost:3036", "ws://localhost:3036"

      # Vite needs script_src for the dev server and eval for sourcemaps
      policy.script_src :self, :https, "http://localhost:3036", :unsafe_eval, :blob

      # Vite/Tailwind need unsafe_inline for HMR style injection
      policy.style_src :self, :https, "http://localhost:3036", :unsafe_inline
    end

    if Rails.env.test?
      policy.script_src :self, :https, :unsafe_eval, :unsafe_inline
    end
  end

  # 1. Generate the nonce
  config.content_security_policy_nonce_generator = lambda { |request|
    # FIX: Do not generate a nonce for Blazer requests.
    return nil if request.path.start_with?("/blazer")
    SecureRandom.base64(16)
  }

  # Apply the CSP nonce only to script-src. We deliberately do NOT nonce style-src
  # because Civic Cookie Control injects <style> blocks at runtime that can't carry
  # our nonce — and per CSP3, a nonce on style-src causes 'unsafe-inline' to be
  # ignored, which would block Civic. Inline-style XSS is materially lower risk
  # than inline-script XSS, so this tradeoff is acceptable.
  config.content_security_policy_nonce_directives = %w[script-src]
end

Rails.application.config.after_initialize do
  Blazer::BaseController.content_security_policy do |policy|
    policy.script_src :self, :unsafe_inline, :unsafe_eval
    policy.style_src :self, :unsafe_inline
  end
end
