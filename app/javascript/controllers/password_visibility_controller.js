import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "iconOn", "iconOff"]

    connect() {
        this.hidden = true
    }

    toggle(e) {
        e.preventDefault()
        this.hidden = !this.hidden

        this.inputTarget.type = this.hidden ? "password" : "text"

        if (this.hidden) {
            this.iconOnTarget.classList.remove("hidden")
            this.iconOffTarget.classList.add("hidden")
        } else {
            this.iconOnTarget.classList.add("hidden")
            this.iconOffTarget.classList.remove("hidden")
        }
    }
}
