import { Controller } from "@hotwired/stimulus"

import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  toggle(event) {
    document.querySelectorAll(".dashboard").forEach(dashboard => {
      dashboard.classList.add("hidden")
    })
    this.loadData(event)
    document.getElementById(`${event.target.value}_dashboard`).classList.toggle("hidden")
  }

  loadData(event) {
    fetch(`/dashboards/fetch_data?q=${event.target.value}`)
    .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json()
      })
      .then((data) => {
        this.buildChart(data.data, event);
      })
      .catch(error => {
        console.error('There was a problem with the fetch operation:', error);
      });
  }

  buildChart(data, event) {
    new Chart(
      document.getElementById(`${event.target.value.toLowerCase()}`),
      {
        type: 'bar',
        data: data
      }
    )
  }
}
