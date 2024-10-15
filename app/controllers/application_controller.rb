class ApplicationController < ActionController::Base
  before_action :authenticate_admin!

  def after_sign_up_path_for(user)
    dashboard_users_path
  end

  def after_sign_in_path_for(user)
    dashboard_users_path
  end
end
