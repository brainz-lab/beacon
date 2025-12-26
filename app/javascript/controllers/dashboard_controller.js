import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Dashboard controller for real-time updates
export default class extends Controller {
  static values = { project: String }

  connect() {
    this.consumer = createConsumer()
    this.subscribeToProject()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  subscribeToProject() {
    this.subscription = this.consumer.subscriptions.create(
      { channel: "ProjectChannel" },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  handleMessage(data) {
    switch (data.type) {
      case "monitor_status":
        this.updateMonitorStatus(data.data)
        break
      case "incident_created":
        this.showIncidentNotification(data.data)
        break
      case "stats_update":
        this.updateStats(data.data)
        break
    }
  }

  updateMonitorStatus(monitor) {
    const element = document.getElementById(`monitor_${monitor.id}`)
    if (element) {
      // Update status dot
      const dot = element.querySelector(".rounded-full")
      if (dot) {
        dot.className = dot.className.replace(/bg-\w+-\d+/, this.statusDotClass(monitor.status))
      }

      // Update status badge
      const badge = element.querySelector("[class*='rounded-full px-2']")
      if (badge) {
        badge.textContent = monitor.status
        badge.className = badge.className.replace(/bg-\w+-\d+ text-\w+-\d+/, this.statusBadgeClass(monitor.status))
      }

      // Update response time
      const responseTime = element.querySelector(".text-gray-500")
      if (responseTime && monitor.response_time) {
        responseTime.textContent = `${monitor.response_time}ms`
      }
    }
  }

  showIncidentNotification(incident) {
    // Show notification toast
    const toast = document.createElement("div")
    toast.className = "fixed bottom-4 right-4 bg-red-600 text-white px-4 py-2 rounded-lg shadow-lg z-50"
    toast.innerHTML = `
      <strong>New Incident:</strong> ${incident.title}
      <a href="/dashboard/incidents/${incident.id}" class="underline ml-2">View</a>
    `
    document.body.appendChild(toast)

    setTimeout(() => toast.remove(), 10000)
  }

  updateStats(stats) {
    const statsElement = document.getElementById("stats")
    if (statsElement) {
      // Update individual stat cards
      Object.entries(stats).forEach(([key, value]) => {
        const statValue = statsElement.querySelector(`[data-stat="${key}"]`)
        if (statValue) {
          statValue.textContent = value
        }
      })
    }
  }

  statusDotClass(status) {
    const classes = {
      healthy: "bg-green-500",
      degraded: "bg-yellow-500",
      down: "bg-red-500",
      paused: "bg-gray-400"
    }
    return classes[status] || "bg-gray-300"
  }

  statusBadgeClass(status) {
    const classes = {
      healthy: "bg-green-100 text-green-800",
      degraded: "bg-yellow-100 text-yellow-800",
      down: "bg-red-100 text-red-800",
      paused: "bg-gray-100 text-gray-800"
    }
    return classes[status] || "bg-gray-100 text-gray-600"
  }
}
