import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName"]

  handleChange(event) {
    const file = event.target.files[0]
    if (file && this.hasFileNameTarget) {
      this.fileNameTarget.textContent = file.name
    }
  }
}
