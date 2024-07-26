class ApplicationController < ActionController::Base
  if Rails.env == "production"
    before_action :authenticate
  end
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["USERNAME"] && password == ENV["PASSWORD"]
    end
  end
end
