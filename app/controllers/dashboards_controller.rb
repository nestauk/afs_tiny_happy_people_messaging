class DashboardsController < ApplicationController
  skip_before_action :authenticate_admin!

  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end
end
