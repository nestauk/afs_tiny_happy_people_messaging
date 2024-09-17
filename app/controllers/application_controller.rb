class ApplicationController < ActionController::Base
  def after_sign_up_path_for(user)
    dashboard_users_path
  end

  def after_sign_in_path_for(user)
    dashboard_users_path
  end
end
