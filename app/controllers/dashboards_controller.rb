class DashboardsController < ApplicationController
  skip_before_action :authenticate_admin!

  def show
    @all_las_dashboard = AllLasDashboard.first
  end
end
