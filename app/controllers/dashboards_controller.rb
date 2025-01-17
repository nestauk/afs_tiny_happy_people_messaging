class DashboardsController < ApplicationController
  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end

  def fetch_sign_up_data
    local_authority = LocalAuthority.find_by(name: params[:q].capitalize)

    grouped_users = local_authority.users
                      .group_by { |user| user.created_at.strftime("%B %Y") }
                      .transform_values { |values| values.count }
 
    data = create_month_array.map { |month| [month, (grouped_users[month].nil? ? 0 : grouped_users[month])] }

    render json: {
      data: {
        labels: data.map(&:first),
        datasets: [{
          label: 'Sign ups over the year',
          data: data.map(&:second),
          fill: false,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      }
    }
  end

  def fetch_click_through_data
    local_authority = LocalAuthority.find_by(name: params[:q].capitalize)

    grouped_users = local_authority.messages.where.not(messages: { content_id: nil })
                      .group_by { |message| message.created_at.strftime("%B %Y") }
                      .transform_values { |values| ((values.select { |m| m.clicked_at.nil?}).count / values.count.to_f) * 100 }
 
    data = create_month_array.map { |month| [month, (grouped_users[month].nil? ? 0 : grouped_users[month])] }

    render json: {
      data: {
        labels: data.map(&:first),
        datasets: [{
          label: 'Sign ups over the year',
          data: data.map(&:second),
          fill: false,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      }
    }
  end

  private

  def create_month_array
    current_month = Date.today.month
    current_year = Date.today.year

    (current_month..12).map { |month| Date.new(current_year - 1, month, 1).strftime("%B %Y") } +
      (1..current_month).map { |month| Date.new(current_year, month, 1).strftime("%B %Y") }
  end
end
