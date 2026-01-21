import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "sourceInput"]

  connect() {
    // Initialize with first tab active
    this.currentIndex = 0
    this.activateFirstTab()
  }

  activateFirstTab() {
    if (this.tabTargets.length > 0) {
      const firstTab = this.tabTargets[0]
      const tabId = firstTab.dataset.tabId || "0"
      this.activateTab(tabId)
      this.updateTabStyles(0)
    }
  }

  switch(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabId
    this.activateTab(tabId)
  }

  // Index-based tab selection (for tabs without tabId)
  select(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.tabsIndex || "0")
    this.currentIndex = index
    this.activateByIndex(index)
    this.updateTabStyles(index)
  }

  activateByIndex(index) {
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove("hidden")
        panel.classList.add("block")
        this.enableInputs(panel)
      } else {
        panel.classList.add("hidden")
        panel.classList.remove("block")
        this.disableInputs(panel)
      }
    })
  }

  updateTabStyles(activeIndex) {
    this.tabTargets.forEach((tab, i) => {
      if (i === activeIndex) {
        tab.classList.add("text-primary", "border-b-2", "border-primary")
        tab.classList.remove("text-text-secondary", "hover:text-text-primary")
      } else {
        tab.classList.remove("text-primary", "border-b-2", "border-primary")
        tab.classList.add("text-text-secondary", "hover:text-text-primary")
      }
    })
  }

  activateTab(tabId) {
    // Update tab styles (legacy tabId-based)
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
        this.enableInputs(panel)
      } else {
        panel.classList.add("hidden")
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
      if (!input.hasAttribute("data-tabs-target")) {
        input.disabled = true
      }
    })
  }
}
