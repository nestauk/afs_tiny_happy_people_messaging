import { Controller } from "@hotwired/stimulus"

import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  toggle(event) {
    document.querySelectorAll(".dashboard").forEach(dashboard => {
      dashboard.classList.add("hidden")
    })
    this.createChart(event)
    document.getElementById(`${event.target.value}_dashboard`).classList.toggle("hidden")
  }

  loadData(event, target) {
    fetch(`/dashboards/fetch_${target}_data?q=${event.target.value}`)
    .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json()
      })
      .then((data) => {
        this.buildChart(data, `${event.target.value.toLowerCase()}-${target}`);
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

  createChart(event) {
    const targets = [ "sign_up", "click_through" ]
    for (var i = 0; i < targets.length; i++) {
      this.loadData(event, targets[i])
    }
  }
}
