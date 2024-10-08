import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()

    document.querySelector(".users-table").classList.toggle("hidden")
  }
}
