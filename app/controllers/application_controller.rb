class ApplicationController < ActionController::Base
  if Rails.env == "production"
    before_action :authenticate
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["USERNAME"] && password == ENV["PASSWORD"]
    end
  end

  def after_sign_up_path_for(user)
    dashboard_users_path
  end

  def after_sign_in_path_for(user)
    dashboard_users_path
  end
end
