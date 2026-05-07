module Dashboards
  class BarChart
    def initialize(timeframe, dataset)
      @labels = Dashboards::ChartLabels.new(timeframe).labels
      @dataset = dataset
    end

    def to_h
      {
        type: "bar",
        data: {
          labels: @labels,
          datasets: [{
            label: "Number of sign ups",
            data: @labels.map { |label| @dataset[label] || 0 },
            fill: false,
            backgroundColor: "#3B82F6",
            borderColor: "#3B82F6",
            tension: 0.1,
          }],
        },
        options: {
          plugins: {
            title: {
              display: true,
              text: "Number of sign ups",
            },
          },
          scales: {
            y: {
              ticks: {
                beginAtZero: true,
              },
            },
          },
        },
      }
    end
  end
end
