import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    target: String
  }

  connect() {
    this.modalElement = this.targetValue
      ? document.getElementById(this.targetValue)
      : this.element
  }

  open(event) {
    event.preventDefault()
    if (this.modalElement) {
      this.modalElement.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.modalElement) {
      this.modalElement.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnClickOutside(event) {
    if (event.target === this.modalElement) {
      this.close()
    }
  }
}
