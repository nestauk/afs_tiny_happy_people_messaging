import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    document.querySelectorAll(".dashboard").forEach(dashboard => {
      dashboard.classList.add("hidden")
    })
    document.getElementById(`${event.target.value}_dashboard`).classList.toggle("hidden")
  }
}
