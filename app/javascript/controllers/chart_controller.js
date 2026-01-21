import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    type: { type: String, default: "bar" },
    data: Object,
    options: Object
  }

  connect() {
    this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  initializeChart() {
    const ctx = this.canvasTarget.getContext("2d")

    this.chart = new Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: this.mergedOptions()
    })
  }

  mergedOptions() {
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: "bottom",
          labels: {
            color: "rgb(156, 163, 175)",
            font: { size: 12 }
          }
        },
        tooltip: {
          backgroundColor: "rgba(17, 24, 39, 0.9)",
          titleColor: "#fff",
          bodyColor: "#fff",
          padding: 12,
          cornerRadius: 8
        }
      },
      scales: this.typeValue === "pie" || this.typeValue === "doughnut" ? {} : {
        x: {
          grid: { color: "rgba(75, 85, 99, 0.2)" },
          ticks: { color: "rgb(156, 163, 175)" }
        },
        y: {
          grid: { color: "rgba(75, 85, 99, 0.2)" },
          ticks: { color: "rgb(156, 163, 175)" },
          beginAtZero: true
        }
      }
    }

    return { ...defaultOptions, ...this.optionsValue }
  }

  updateData(newData) {
    if (this.chart) {
      this.chart.data = newData
      this.chart.update()
    }
  }
}
