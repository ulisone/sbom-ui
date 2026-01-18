import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    // Load saved theme or default to system preference
    if (!("theme" in localStorage)) {
        if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
            this.setTheme("dark")
        } else {
            this.setTheme("light")
        }
    } else {
        this.setTheme(localStorage.theme)
    }
  }

  toggle() {
    const currentTheme = document.documentElement.classList.contains("dark") ? "dark" : "light"
    const newTheme = currentTheme === "dark" ? "light" : "dark"
    this.setTheme(newTheme)
  }

  setTheme(theme) {
    if (theme === "dark") {
      document.documentElement.classList.add("dark")
    } else {
      document.documentElement.classList.remove("dark")
    }
    localStorage.setItem("theme", theme)
  }
}