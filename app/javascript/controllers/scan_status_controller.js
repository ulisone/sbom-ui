import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 3000 }
  }

  connect() {
    this.checkStatus()
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollTimer = setInterval(() => {
      this.checkStatus()
    }, this.intervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue)
      const data = await response.json()

      if (data.completed || data.status === "failed") {
        this.stopPolling()
        // Reload the page to show results
        window.location.reload()
      }
    } catch (error) {
      console.error("Error checking scan status:", error)
    }
  }
}
