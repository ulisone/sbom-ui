import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    data: Object,
    width: { type: Number, default: 800 },
    height: { type: Number, default: 600 }
  }

  connect() {
    if (this.hasDataValue && Object.keys(this.dataValue).length > 0) {
      this.render()
    }
  }

  disconnect() {
    if (this.svg) {
      this.svg.remove()
    }
  }

  render() {
    const container = this.containerTarget
    container.innerHTML = ""

    const width = this.widthValue || container.clientWidth || 800
    const height = this.heightValue || 600
    const margin = { top: 20, right: 120, bottom: 20, left: 120 }

    // Create SVG
    this.svg = d3.select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [0, 0, width, height])
      .attr("style", "max-width: 100%; height: auto;")

    const g = this.svg.append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`)

    // Create tree layout
    const treeWidth = width - margin.left - margin.right
    const treeHeight = height - margin.top - margin.bottom

    const tree = d3.tree().size([treeHeight, treeWidth])

    // Create hierarchy from data
    const root = d3.hierarchy(this.dataValue)
    tree(root)

    // Draw links
    const link = g.selectAll(".link")
      .data(root.links())
      .enter()
      .append("path")
      .attr("class", "link")
      .attr("fill", "none")
      .attr("stroke", "#4b5563")
      .attr("stroke-opacity", 0.6)
      .attr("stroke-width", 1.5)
      .attr("d", d3.linkHorizontal()
        .x(d => d.y)
        .y(d => d.x))

    // Draw nodes
    const node = g.selectAll(".node")
      .data(root.descendants())
      .enter()
      .append("g")
      .attr("class", "node")
      .attr("transform", d => `translate(${d.y},${d.x})`)

    // Add circles for nodes
    node.append("circle")
      .attr("r", d => d.data.vulnerable ? 8 : 6)
      .attr("fill", d => this.getNodeColor(d.data))
      .attr("stroke", d => d.data.vulnerable ? "#dc2626" : "#6b7280")
      .attr("stroke-width", d => d.data.vulnerable ? 2 : 1)
      .style("cursor", "pointer")
      .on("mouseover", (event, d) => this.showTooltip(event, d))
      .on("mouseout", () => this.hideTooltip())
      .on("click", (event, d) => this.handleNodeClick(d))

    // Add labels
    node.append("text")
      .attr("dy", "0.31em")
      .attr("x", d => d.children ? -10 : 10)
      .attr("text-anchor", d => d.children ? "end" : "start")
      .attr("fill", "#9ca3af")
      .attr("font-size", "11px")
      .text(d => this.formatLabel(d.data))

    // Add vulnerability count badges
    node.filter(d => d.data.vulnCount > 0)
      .append("text")
      .attr("dy", "-12")
      .attr("x", 0)
      .attr("text-anchor", "middle")
      .attr("fill", "#dc2626")
      .attr("font-size", "10px")
      .attr("font-weight", "bold")
      .text(d => d.data.vulnCount)

    // Create tooltip
    this.tooltip = d3.select(container)
      .append("div")
      .attr("class", "tooltip")
      .style("position", "absolute")
      .style("visibility", "hidden")
      .style("background", "rgba(17, 24, 39, 0.95)")
      .style("color", "#fff")
      .style("padding", "12px")
      .style("border-radius", "8px")
      .style("font-size", "12px")
      .style("max-width", "300px")
      .style("z-index", "1000")
      .style("pointer-events", "none")
      .style("box-shadow", "0 4px 12px rgba(0,0,0,0.3)")

    // Add zoom behavior
    const zoom = d3.zoom()
      .scaleExtent([0.5, 3])
      .on("zoom", (event) => {
        g.attr("transform", event.transform)
      })

    this.svg.call(zoom)
  }

  getNodeColor(data) {
    if (data.vulnerable) {
      if (data.severity === "CRITICAL") return "#dc2626"
      if (data.severity === "HIGH") return "#ea580c"
      if (data.severity === "MEDIUM") return "#ca8a04"
      return "#16a34a"
    }
    return data.children ? "#3b82f6" : "#6b7280"
  }

  formatLabel(data) {
    const name = data.name || "Unknown"
    const version = data.version ? `@${data.version}` : ""
    const label = `${name}${version}`
    return label.length > 25 ? label.substring(0, 22) + "..." : label
  }

  showTooltip(event, d) {
    const data = d.data
    let content = `<strong>${data.name || "Package"}</strong>`

    if (data.version) {
      content += `<br>Version: ${data.version}`
    }
    if (data.ecosystem) {
      content += `<br>Ecosystem: ${data.ecosystem}`
    }
    if (data.license) {
      content += `<br>License: ${data.license}`
    }
    if (data.vulnCount > 0) {
      content += `<br><span style="color: #f87171">Vulnerabilities: ${data.vulnCount}</span>`
    }
    if (data.vulnerable) {
      content += `<br><span style="color: #f87171">Severity: ${data.severity}</span>`
    }

    this.tooltip
      .style("visibility", "visible")
      .html(content)
      .style("left", (event.pageX + 10) + "px")
      .style("top", (event.pageY - 10) + "px")
  }

  hideTooltip() {
    this.tooltip.style("visibility", "hidden")
  }

  handleNodeClick(d) {
    const data = d.data
    if (data.purl || data.id) {
      // Navigate to dependency detail or package page
      const event = new CustomEvent("dependency:selected", {
        detail: { dependency: data },
        bubbles: true
      })
      this.element.dispatchEvent(event)
    }
  }

  updateData(newData) {
    this.dataValue = newData
    this.render()
  }
}
