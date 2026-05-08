import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["cell", "value", "options"];

  connect() {
    // console.log("Cell controller connected");
  }

  toggleOptions() {
    if (this.cellTarget.dataset.value !== "0") return;
    this.optionsTarget.classList.toggle("d-none");
    this.valueTarget.classList.toggle("d-none");
  }
}
