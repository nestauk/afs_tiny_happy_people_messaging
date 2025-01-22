import { Controller } from "@hotwired/stimulus"

import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  filter(event) {
    this.destroyCharts()
    const council = document.querySelector("select#category").value
    this.createChart(council, event.target.value)
  }

  toggle(event) {
    document.querySelectorAll(".dashboard").forEach(dashboard => {
      dashboard.classList.add("hidden")
    })
    this.createChart(event.target.value, "year")
    document.getElementById(`${event.target.value}_dashboard`).classList.toggle("hidden")
  }

  loadData(council, timeframe, target) {
    fetch(`/dashboards/fetch_${target}_data?q=${council}&timeframe=${timeframe}`)
    .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json()
      })
      .then((data) => {
        this.buildChart(data, `${council.toLowerCase()}-${target}`);
      })
      .catch(error => {
        console.error('There was a problem with the fetch operation:', error);
      });
  }

  buildChart(data, target) {
    new Chart(
      document.getElementById(`${target}`),
      data
    )
  }

  createChart(council, timeframe) {
    const targets = [ "sign_up", "click_through" ]
    for (var i = 0; i < targets.length; i++) {
      this.loadData(council, timeframe, targets[i])
    }
  }

  destroyCharts() {
    const charts = document.querySelector("div.dashboard:not(.hidden)").getElementsByTagName('canvas')
    for (var i = 0; i < charts.length; i++) {
      Chart.getChart(charts[i].id).destroy()
    }
  }
}
