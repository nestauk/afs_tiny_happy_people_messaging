class SessionsController < Devise::Passwordless::SessionsController
  prepend_before_action :check_ip, only: [:new, :create]

  private

  def check_ip
    if Rails.env.production? && request.ip != ENV.fetch("ADMIN_IP_WHITELIST")
      redirect_to root_path, alert: "Access denied."
    end
  end
end
