class DashboardsController < ApplicationController
  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end

  def fetch_data
    local_authority = LocalAuthority.find_by(name: params[:q].capitalize)

    users = User.joins(:local_authority).where(local_authority: {name: local_authority.name})
        .select("DATE_TRUNC('month', users.created_at) as month, COUNT(*) as count")
        .group("DATE_TRUNC('month', users.created_at)")
        .order("month ASC")
        .map { |user| { "#{user.month.strftime("%B %Y")}": user.count } }
    render json: {
      data: {
        labels: users.map(&:keys).flatten,
        datasets: [{
          label: 'Sign ups over the year',
          data: users.map(&:values).flatten,
          fill: false,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      }
    }
  end
end
