import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Monitor detail page controller with real-time updates
export default class extends Controller {
  static values = { id: String }

  connect() {
    this.consumer = createConsumer()
    this.subscribeToMonitor()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  subscribeToMonitor() {
    this.subscription = this.consumer.subscriptions.create(
      { channel: "MonitorChannel", id: this.idValue },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  handleMessage(data) {
    switch (data.type) {
      case "check_result":
        this.addCheckResult(data.data)
        break
      case "status_change":
        this.updateStatus(data.data)
        break
      case "incident_created":
        this.showIncident(data.data)
        break
    }
  }

  addCheckResult(check) {
    const checksList = document.getElementById("checks-list")
    if (!checksList) return

    const row = document.createElement("tr")
    row.innerHTML = `
      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        ${new Date(check.checked_at).toLocaleTimeString()}
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${check.status === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
          ${check.status === 'success' ? 'OK' : 'FAIL'}
        </span>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        ${check.response_time}ms
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        ${check.region?.toUpperCase() || '-'}
      </td>
    `

    // Add to top of list
    checksList.insertBefore(row, checksList.firstChild)

    // Remove old rows if too many
    while (checksList.children.length > 50) {
      checksList.removeChild(checksList.lastChild)
    }

    // Highlight new row briefly
    row.classList.add("bg-yellow-50")
    setTimeout(() => row.classList.remove("bg-yellow-50"), 2000)
  }

  updateStatus(data) {
    // Reload the page to show updated status
    // In production, would update specific elements
    Turbo.visit(window.location.href, { action: "replace" })
  }

  showIncident(incident) {
    // Show notification
    const notification = document.createElement("div")
    notification.className = "fixed bottom-4 right-4 bg-red-600 text-white px-4 py-2 rounded-lg shadow-lg z-50"
    notification.innerHTML = `New incident: ${incident.title}`
    document.body.appendChild(notification)
    setTimeout(() => notification.remove(), 5000)
  }
}
