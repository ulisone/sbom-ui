import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "vulnerabilityRules", "licenseRules", "riskScoreRules"]

  connect() {
    this.updateRulesVisibility()
  }

  typeChanged() {
    this.updateRulesVisibility()
  }

  updateRulesVisibility() {
    const type = this.typeSelectTarget.value

    // Hide all rule sections
    this.vulnerabilityRulesTarget.classList.add("hidden")
    this.licenseRulesTarget.classList.add("hidden")
    this.riskScoreRulesTarget.classList.add("hidden")

    // Show relevant section
    switch (type) {
      case "vulnerability_threshold":
        this.vulnerabilityRulesTarget.classList.remove("hidden")
        break
      case "license_allowlist":
      case "license_blocklist":
        this.licenseRulesTarget.classList.remove("hidden")
        break
      case "risk_score_limit":
        this.riskScoreRulesTarget.classList.remove("hidden")
        break
    }
  }
}
