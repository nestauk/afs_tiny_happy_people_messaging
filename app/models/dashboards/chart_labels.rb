module Dashboards
  class ChartLabels
    FORMATS = {
      "week" => "%d %B %Y",
      "month" => "%d %B %Y",
      "year" => "%B %Y",
    }.freeze

    def initialize(timeframe)
      @timeframe = timeframe
    end

    def labels
      case @timeframe
      when "year" then year_labels
      when "month" then month_labels
      when "week" then week_labels
      end
    end

    def format
      FORMATS[@timeframe]
    end

    private

    def year_labels
      current_month = Time.zone.today.month
      ((current_month + 1)..12).map { |month| format_date(1.year.ago.year, month, 1) } +
        (1..current_month).map { |month| format_date(Time.zone.today.year, month, 1) }
    end

    def month_labels
      current_day = Time.zone.today.day
      ((1.month.ago.day + 1)..1.month.ago.end_of_month.day).map { |day| format_date(1.month.ago.year, 1.month.ago.month, day) } +
        (1..current_day).map { |day| format_date(Time.zone.today.year, Time.zone.today.month, day) }
    end

    def week_labels
      current_day = Time.zone.today.day
      if current_day <= 7
        ((1.week.ago.day + 1)..1.week.ago.end_of_month.day).map { |day| format_date(1.week.ago.year, 1.week.ago.month, day) } +
          (1..current_day).map { |day| format_date(Time.zone.today.year, Time.zone.today.month, day) }
      else
        ((current_day - 6)..current_day).map { |day| format_date(Time.zone.today.year, Time.zone.today.month, day) }
      end
    end

    def format_date(year, month, day)
      Date.new(year, month, day).strftime(format)
    end
  end
end
