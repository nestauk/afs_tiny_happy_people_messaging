class DashboardsController < ApplicationController
  before_action :set_local_authority, except: [:show]
  before_action :set_timeframe, except: [:show]

  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end

  def fetch_sign_up_data
    grouped_users = @local_authority.users
      .group_by { |user| user.created_at.strftime(timeframe) }
      .transform_values { |values| values.count }

    data = create_labels.map { |label| [label, (grouped_users[label].nil? ? 0 : grouped_users[label])] }

    render_bar_chart(data)
  end

  def fetch_click_through_data
    grouped_users = @local_authority.messages.where.not(messages: {content_id: nil})
      .group_by { |message| message.created_at.strftime(timeframe) }
      .transform_values { |values| ((values.select { |m| !m.clicked_at.nil? }).count.to_f / values.count.to_f) * 100 }

    click_through = create_labels.map { |label| [label, (grouped_users[label].nil? ? 0 : grouped_users[label])] }

    grouped_number = @local_authority.messages.where.not(messages: {content_id: nil}).group_by { |message| message.created_at.strftime(timeframe) }.transform_values { |values| values.count }
    overall_number = create_labels.map { |label| [label, (grouped_number[label].nil? ? 0 : grouped_number[label])] }

    render_line_chart(click_through, overall_number)
  end

  private

  def create_labels
    if @timeframe == "year"
      current_month = Date.today.month
      current_year = Date.today.year

      (current_month..12).map { |month| Date.new(current_year - 1, month, 1).strftime(timeframe) } +
        (1..current_month).map { |month| Date.new(current_year, month, 1).strftime(timeframe) }
    elsif @timeframe == "month"
      current_day = Date.today.day

      (1.month.ago.day..1.month.ago.end_of_month.day).map { |day| Date.new(Date.today.year, 1.month.ago.month, day).strftime(timeframe) } +
        (1..current_day).map { |day| Date.new(Date.today.year, Date.today.month, day).strftime(timeframe) }
    elsif @timeframe == "week"
      current_day = Date.today.day

      ((current_day - 7)..current_day).map { |day| Date.new(Date.today.year, Date.today.month, day).strftime(timeframe) }
    end
  end

  def render_bar_chart(data)
    render json: {
      type: "bar",
      data: {
        labels: data.map(&:first),
        datasets: [{
          label: "Number of sign ups",
          data: data.map(&:second),
          fill: false,
          backgroundColor: "#3B82F6",
          borderColor: "#3B82F6",
          tension: 0.1
        }]
      }
    }
  end

  def render_line_chart(click_through, overall_number)
    render json: {
      type: "line",
      data: {
        labels: click_through.map(&:first),
        datasets: [{
          label: "Click through rate",
          data: click_through.map(&:second),
          fill: false,
          borderColor: "rgb(75, 192, 192)",
          backgroundColor: "rgb(75, 192, 192)",
          tension: 0.1
        },
          {
            label: "Number of messages",
            data: overall_number.map(&:second),
            fill: false,
            borderColor: "rgb(255, 99, 132)",
            backgroundColor: "rgb(255, 99, 132)"
          }],
        options: {
          responsive: true,
          interaction: {
            mode: "index",
            intersect: false
          },
          stacked: false,
          scales: {
            y: {
              type: "linear",
              display: true,
              position: "left"
            },
            y1: {
              type: "linear",
              display: true,
              position: "right",
              grid: {
                drawOnChartArea: false
              }
            }
          }
        }
      }
    }
  end

  def set_local_authority
    @local_authority = LocalAuthority.find_by(name: params[:q].gsub("_", " ").titleize)
  end

  def set_timeframe
    @timeframe = params[:timeframe]
  end

  def timeframe
    if @timeframe == "week" || @timeframe == "month"
      "%d %B"
    elsif @timeframe == "year"
      "%B %Y"
    end
  end
end
