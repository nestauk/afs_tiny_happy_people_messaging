import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (document.getElementById("diary_entry_form_did_previous_week_activity_true") && document.getElementById("diary_entry_form_did_previous_week_activity_true").checked) {
      document.querySelector(".diary_entry_form_activities_from_previous_weeks").classList.remove("hidden")
    }
  }

  toggle(event) {
    event.preventDefault()

    document.querySelector(".users-table").classList.toggle("hidden")
  }

  showForm(event) {
    if (event.target.value == "true") {
      document.querySelector(".diary_entry_form_activities_from_previous_weeks").classList.remove("hidden")
    } else {
      document.querySelector(".diary_entry_form_activities_from_previous_weeks").classList.add("hidden")
      document.querySelector(".diary_entry_form_activities_from_previous_weeks").children[1].innerHTML = ""
    }
  }
}
