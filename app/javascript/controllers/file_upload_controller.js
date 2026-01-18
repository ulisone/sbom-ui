import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "preview", "fileList"]

  connect() {
    this.files = []
  }

  // Drag events
  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-primary", "bg-primary-light")
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary-light")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary-light")

    const droppedFiles = Array.from(event.dataTransfer.files)
    this.addFiles(droppedFiles)
  }

  // Click to browse
  browse() {
    this.inputTarget.click()
  }

  // Handle file selection from input
  handleFileSelect(event) {
    const selectedFiles = Array.from(event.target.files)
    this.addFiles(selectedFiles)
  }

  addFiles(newFiles) {
    // Accept all files - SBOM Engine handles format detection
    this.files = [...this.files, ...newFiles]
    this.updatePreview()
    this.updateFileInput()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.updatePreview()
    this.updateFileInput()
  }

  updatePreview() {
    if (!this.hasPreviewTarget) return

    if (this.files.length === 0) {
      this.previewTarget.classList.add("hidden")
      return
    }

    this.previewTarget.classList.remove("hidden")
    this.fileListTarget.innerHTML = this.files.map((file, index) => `
      <div class="flex items-center justify-between p-3 bg-surface rounded-lg border border-border">
        <div class="flex items-center gap-3">
          <svg class="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <div>
            <p class="text-sm font-medium text-text-primary">${file.name}</p>
            <p class="text-xs text-text-muted">${this.formatFileSize(file.size)}</p>
          </div>
        </div>
        <button type="button"
                class="text-text-muted hover:text-critical transition-colors"
                data-action="click->file-upload#removeFile"
                data-index="${index}">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `).join("")
  }

  updateFileInput() {
    // Create a new DataTransfer to update the file input
    const dataTransfer = new DataTransfer()
    this.files.forEach(file => dataTransfer.items.add(file))
    this.inputTarget.files = dataTransfer.files
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }

  showNotification(message, type = "info") {
    const notification = document.createElement("div")
    notification.className = `alert alert-${type} fixed bottom-4 right-4 z-50 max-w-sm`
    notification.textContent = message
    document.body.appendChild(notification)
    setTimeout(() => notification.remove(), 3000)
  }
}
