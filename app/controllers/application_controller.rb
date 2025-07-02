class ApplicationController < ActionController::Base
  before_action :authenticate_admin!

  def after_sign_in_path_for(resource)
    if resource.role == "local_authority"
      dashboard_path
    elsif resource.role == "admin"
      dashboard_users_path
    end
  end

  private

  def check_admin_role
    redirect_to root_path unless current_admin.role == "admin"
  end
end
