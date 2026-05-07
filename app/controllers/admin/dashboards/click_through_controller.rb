class Admin::Dashboards::ClickThroughController < Admin::Dashboards::BaseController
  def show
    percentages = @local_authority.percentage_messages_clicked_by_created_at(timeframe_format)
    counts = @local_authority.count_messages_by_created_at(timeframe_format)
    render json: Dashboards::LineChart.new(timeframe, percentages, counts).to_h
  end
end
