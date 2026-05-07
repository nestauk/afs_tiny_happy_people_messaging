class Admin::Dashboards::SignUpController < Admin::Dashboards::BaseController
  def show
    dataset = @local_authority.count_users_by_created_at(timeframe_format)
    render json: Dashboards::BarChart.new(timeframe, dataset).to_h
  end
end
