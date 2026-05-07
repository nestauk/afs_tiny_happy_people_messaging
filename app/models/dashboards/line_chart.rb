module Dashboards
  class LineChart
    def initialize(timeframe, percentages, counts)
      @labels = Dashboards::ChartLabels.new(timeframe).labels
      @percentages = percentages
      @counts = counts
    end

    def to_h
      {
        type: "line",
        data: {
          labels: @labels,
          datasets: [
            {
              label: "Click through rate",
              data: @labels.map { |label| @percentages[label] || 0 },
              fill: false,
              borderColor: "rgb(75, 192, 192)",
              backgroundColor: "rgb(75, 192, 192)",
              yAxisID: "y",
            },
            {
              label: "Number of messages",
              data: @labels.map { |label| @counts[label] || 0 },
              fill: false,
              borderColor: "rgb(255, 99, 132)",
              backgroundColor: "rgb(255, 99, 132)",
              yAxisID: "y1",
            },
          ],
        },
        options: {
          responsive: true,
          interaction: {
            mode: "index",
            intersect: false,
          },
          stacked: false,
          plugins: {
            title: {
              display: true,
              text: "Percentage of messages clicked",
            },
          },
          scales: {
            y: {
              type: "linear",
              display: true,
              position: "left",
              min: 0,
            },
            y1: {
              type: "linear",
              display: true,
              position: "right",
              min: 0,
            },
          },
        },
      }
    end
  end
end
