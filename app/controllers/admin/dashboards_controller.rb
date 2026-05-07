class Admin::DashboardsController < ApplicationController
  def show
    @hide_sidebar = true
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end
end
