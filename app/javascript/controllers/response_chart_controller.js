import { Controller } from "@hotwired/stimulus"

// Response time chart controller
// Uses a simple canvas-based chart (in production would use Chart.js)
export default class extends Controller {
  static values = { monitor: String }

  connect() {
    this.loadData()
  }

  async loadData() {
    try {
      const response = await fetch(`/api/v1/monitors/${this.monitorValue}/checks?limit=50`)
      const data = await response.json()
      this.renderChart(data.checks || [])
    } catch (error) {
      console.error("Failed to load chart data:", error)
      this.renderEmptyState()
    }
  }

  renderChart(checks) {
    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const ctx = canvas.getContext("2d")
    const width = canvas.width = canvas.offsetWidth
    const height = canvas.height = canvas.offsetHeight

    // Clear canvas
    ctx.clearRect(0, 0, width, height)

    if (checks.length === 0) {
      this.renderEmptyState()
      return
    }

    // Get response times
    const responseTimes = checks.map(c => c.response_time || 0).reverse()
    const max = Math.max(...responseTimes, 100)
    const min = 0

    // Draw grid
    ctx.strokeStyle = "#e5e7eb"
    ctx.lineWidth = 1
    for (let i = 0; i <= 4; i++) {
      const y = (height / 4) * i
      ctx.beginPath()
      ctx.moveTo(0, y)
      ctx.lineTo(width, y)
      ctx.stroke()
    }

    // Draw response time line
    ctx.strokeStyle = "#10b981"
    ctx.lineWidth = 2
    ctx.beginPath()

    const step = width / (responseTimes.length - 1 || 1)

    responseTimes.forEach((rt, i) => {
      const x = i * step
      const y = height - ((rt - min) / (max - min)) * height

      if (i === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })

    ctx.stroke()

    // Draw points
    ctx.fillStyle = "#10b981"
    responseTimes.forEach((rt, i) => {
      const x = i * step
      const y = height - ((rt - min) / (max - min)) * height

      ctx.beginPath()
      ctx.arc(x, y, 3, 0, Math.PI * 2)
      ctx.fill()
    })

    // Draw labels
    ctx.fillStyle = "#6b7280"
    ctx.font = "12px sans-serif"
    ctx.textAlign = "left"
    ctx.fillText(`${max}ms`, 5, 15)
    ctx.fillText(`${Math.round(max / 2)}ms`, 5, height / 2 + 5)
    ctx.fillText("0ms", 5, height - 5)
  }

  renderEmptyState() {
    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const ctx = canvas.getContext("2d")
    const width = canvas.width = canvas.offsetWidth
    const height = canvas.height = canvas.offsetHeight

    ctx.clearRect(0, 0, width, height)
    ctx.fillStyle = "#9ca3af"
    ctx.font = "14px sans-serif"
    ctx.textAlign = "center"
    ctx.fillText("No check data available yet", width / 2, height / 2)
  }
}
