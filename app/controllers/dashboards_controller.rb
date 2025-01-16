class DashboardsController < ApplicationController
  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end
end
