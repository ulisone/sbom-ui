import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "sourceInput"]

  connect() {
    // Initialize with first tab active
    this.activateFirstTab()
  }

  activateFirstTab() {
    if (this.tabTargets.length > 0) {
      const firstTab = this.tabTargets[0]
      this.activateTab(firstTab.dataset.tabId)
    }
  }

  switch(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabId
    this.activateTab(tabId)
  }

  activateTab(tabId) {
    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tabId === tabId) {
        tab.classList.add("bg-primary", "text-white")
        tab.classList.remove("bg-surface", "text-text-secondary", "hover:bg-surface-hover")
      } else {
        tab.classList.remove("bg-primary", "text-white")
        tab.classList.add("bg-surface", "text-text-secondary", "hover:bg-surface-hover")
      }
    })

    // Show/hide panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tabId === tabId) {
        panel.classList.remove("hidden")
        // Enable/disable inputs in this panel
        this.enableInputs(panel)
      } else {
        panel.classList.add("hidden")
        // Disable inputs in hidden panels
        this.disableInputs(panel)
      }
    })
  }

  enableInputs(panel) {
    panel.querySelectorAll("input, select, textarea").forEach(input => {
      input.disabled = false
    })
  }

  disableInputs(panel) {
    panel.querySelectorAll("input, select, textarea").forEach(input => {
      // Don't disable the source input hidden field
      if (!input.hasAttribute("data-tabs-target")) {
        input.disabled = true
      }
    })
  }
}
