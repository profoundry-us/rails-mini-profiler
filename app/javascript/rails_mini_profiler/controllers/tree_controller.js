import { Controller } from "@hotwired/stimulus";

// Expand/collapse a node in the trace tree. Each node is its own controller so a toggle only affects
// that node's direct children.
export default class extends Controller {
  static targets = ["children", "toggle"];

  toggle() {
    if (!this.hasChildrenTarget) return;

    const hidden = this.childrenTarget.classList.toggle("hidden");
    const expanded = !hidden;

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", String(expanded));
    }
    this.element.classList.toggle("trace-node--expanded", expanded);
  }
}
