import { Controller } from "@hotwired/stimulus"

// Monitor form controller for dynamic field visibility
export default class extends Controller {
  static targets = ["httpFields", "hostFields", "dnsFields"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const typeSelect = this.element.querySelector("select[name='monitor[check_type]']")
    if (!typeSelect) return

    const type = typeSelect.value

    // Show/hide HTTP fields
    const httpFields = document.getElementById("http-fields")
    const hostFields = document.getElementById("host-fields")
    const dnsFields = document.getElementById("dns-fields")
    const portField = document.getElementById("port-field")

    if (httpFields) {
      httpFields.classList.toggle("hidden", type !== "http")
    }

    if (hostFields) {
      hostFields.classList.toggle("hidden", type === "http")
    }

    if (dnsFields) {
      dnsFields.classList.toggle("hidden", type !== "dns")
    }

    if (portField) {
      portField.classList.toggle("hidden", type === "ping" || type === "dns")
    }
  }
}
