import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()

    document.querySelector(".users-table").classList.toggle("hidden")
  }

  showForm(event) {
    if (event.target.value == "Email") {
      document.querySelector(".user_profile_email").classList.remove("hidden")
    } else if (event.target.value == "Phone call") {
      document.querySelector(".user_profile_email").classList.add("hidden")
    }
  }
}
