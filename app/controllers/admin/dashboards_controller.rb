class Admin::DashboardsController < ApplicationController
  before_action :set_local_authority, except: [:show]
  before_action :set_timeframe, except: [:show]

  def show
    @q = LocalAuthority.all
    @all_las_dashboard = AllLasDashboard.first
    @specific_la_dashboards = LaSpecificDashboard.all
  end

  def fetch_sign_up_data
    grouped_users = @local_authority.count_users_by_created_at(timeframe)

    render_bar_chart(create_data(grouped_users))
  end

  def fetch_click_through_data
    grouped_percentage = @local_authority.percentage_messages_clicked_by_created_at(timeframe)
    grouped_count = @local_authority.count_messages_by_created_at(timeframe)

    render_line_chart(create_data(grouped_percentage), create_data(grouped_count))
  end

  private

  def create_labels
    if @timeframe == "year"
      current_month = Date.today.month

      ((current_month + 1)..12).map { |month| create_date(1.year.ago.year, month, 1) } +
        (1..current_month).map { |month| create_date(Date.today.year, month, 1) }
    elsif @timeframe == "month"
      current_day = Date.today.day

      ((1.month.ago.day + 1)..1.month.ago.end_of_month.day).map { |day| create_date(1.month.ago.year, 1.month.ago.month, day) } +
        (1..current_day).map { |day| create_date(Date.today.year, Date.today.month, day) }
    elsif @timeframe == "week"
      current_day = Date.today.day

      if current_day <= 7
        ((1.week.ago.day + 1)..1.week.ago.end_of_month.day).map { |day| create_date(1.week.ago.year, 1.week.ago.month, day) } +
          (1..current_day).map { |day| create_date(Date.today.year, Date.today.month, day) }
      else
        ((current_day - 6)..current_day).map { |day| create_date(Date.today.year, Date.today.month, day) }
      end
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
      },
      options: {
        plugins: {
          title: {
            display: true,
            text: "Number of sign ups"
          }
        },
        scales: {
          y: {
            ticks: {
              beginAtZero: true
            }
          }
        }
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
          yAxisID: "y"
        },
          {
            label: "Number of messages",
            data: overall_number.map(&:second),
            fill: false,
            borderColor: "rgb(255, 99, 132)",
            backgroundColor: "rgb(255, 99, 132)",
            yAxisID: "y1"
          }]
      },
      options: {
        responsive: true,
        interaction: {
          mode: "index",
          intersect: false
        },
        stacked: false,
        plugins: {
          title: {
            display: true,
            text: "Percentage of messages clicked"
          }
        },
        scales: {
          y: {
            type: "linear",
            display: true,
            position: "left",
            min: 0
          },
          y1: {
            type: "linear",
            display: true,
            position: "right",
            min: 0
          }
        }
      }
    }
  end

  def set_local_authority
    nocaps = ["and", "of", "with"]
    name = params[:q].split("_").map { |word| nocaps.include?(word) ? word : word.capitalize }.join(" ")

    @local_authority = LocalAuthority.find_by(name:)
  end

  def set_timeframe
    @timeframe = params[:timeframe]
  end

  def timeframe
    if @timeframe == "week" || @timeframe == "month"
      "%d %B %Y"
    elsif @timeframe == "year"
      "%B %Y"
    end
  end

  def create_data(dataset)
    create_labels.map { |label| [label, (dataset[label].nil? ? 0 : dataset[label])] }
  end

  def create_date(year, month, day)
    Date.new(year, month, day).strftime(timeframe)
  end
end
