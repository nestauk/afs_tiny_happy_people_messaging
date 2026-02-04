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
    policy.script_src :self, :https
    policy.style_src :self, :https

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

  # 2. FIX: Only apply the nonce to styles if we ARE NOT in development.
  # If we are in dev, we only apply it to script-src.
  config.content_security_policy_nonce_directives = if Rails.env.development?
    %w[script-src]
  else
    %w[script-src style-src]
  end
end

Rails.application.config.after_initialize do
  Blazer::QueriesController.content_security_policy do |policy|
    policy.script_src :self, :unsafe_inline, :unsafe_eval
    policy.style_src :self, :unsafe_inline
  end
end
