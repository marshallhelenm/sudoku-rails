import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static targets = ["cell", "messageCard"];

  static values = {
    val: Number,
    difficulty: { type: String, default: "medium" },
    showOptions: { type: Boolean, default: false },
  };

  toggleOptions(e) {
    this.showOptionsValue = !this.showOptionsValue;
    this.cellTargets.forEach((cell) => {
      if (cell.dataset.value !== "0") return;
      cell
        .querySelector(".cell-options")
        .classList.toggle("d-none", !this.showOptionsValue);
      cell
        .querySelector(".cell-value")
        .classList.toggle("d-none", this.showOptionsValue);
    });
    e.target.textContent =
      e.target.textContent === "Show Options" ? "Hide Options" : "Show Options";
  }

  async solve() {
    const speed = event.currentTarget.dataset.speed || "fast";
    if (speed === "slow") {
      this.showOptionsValue = true;
      this.cellTargets.forEach((cell) => {
        if (cell.dataset.value !== "0") return;
        cell
          .querySelector(".cell-options")
          .classList.toggle("d-none", !this.showOptionsValue);
        cell
          .querySelector(".cell-value")
          .classList.toggle("d-none", this.showOptionsValue);
      });
      this.clearEditMode();
    }
    const response = await patch("/sudoku/solve_puzzle", {
      responseKind: "turbo-stream",
      body: { speed: event.currentTarget.dataset.speed || "fast" },
    });
  }

  async newPuzzle() {
    this.closeResultCard();
    this.showSpinner();
    await patch("/sudoku/new_puzzle", {
      responseKind: "turbo-stream",
      body: this.difficultyValue ? { difficulty: this.difficultyValue } : {},
    });
  }

  showSpinner() {
    const spinner = document.getElementById("game-board-spinner");
    if (spinner) spinner.classList.remove("d-none");
  }

  hideSpinner() {
    const spinner = document.getElementById("game-board-spinner");
    if (spinner) spinner.classList.add("d-none");
  }

  connect() {
    // Hide spinner on turbo stream render
    document.addEventListener("turbo:before-stream-render", this.hideSpinner);
    // ...existing code...
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-stream-render",
      this.hideSpinner,
    );
  }

  // async generatePuzzles() {
  //   const response = await patch("/sudoku/generate_puzzles", {
  //     responseKind: "turbo-stream",
  //   });
  // }

  changeDifficulty(e) {
    const difficulty = e.target.value;
    const url = new URL(window.location);
    url.searchParams.set("difficulty", difficulty);
    window.history.pushState({}, "", url);
    this.showSpinner();
    this.difficultyValue = difficulty;
    this.newPuzzle();
  }

  toggleEditMode(e) {
    // turn other cells off edit mode
    this.cellTargets.forEach((cell) => {
      if (cell !== e.currentTarget) {
        cell.classList.remove("edit-mode");
      }
    });
    e.currentTarget.classList.toggle("edit-mode");
  }

  toggleCellOptions(e) {
    e.stopPropagation();
    var cell = e.currentTarget.closest(".cell");
    if (cell.dataset.value !== "0") return;
    cell.querySelector(".cell-options").classList.toggle("d-none");
    cell.querySelector(".cell-value").classList.toggle("d-none");
  }

  setCellValue(cell, value) {
    let valueInteger = parseInt(value, 10);
    cell.dataset.value = valueInteger;
    if (valueInteger === 0) {
      cell.querySelector(".cell-value").textContent = "";
    } else {
      cell.querySelector(".cell-value").textContent = valueInteger;
    }
    // update 'values' cookie
    let valuesCookie = this.loadValuesCookie() || {};
    valuesCookie[cell.dataset.row][cell.dataset.col] = valueInteger;
    document.cookie = "values=" + JSON.stringify(valuesCookie) + "; path=/";
  }

  updateCellOptions(cell, option) {
    let optionInteger = parseInt(option, 10);
    const optionsContainer = cell.querySelector(".cell-options");
    let options = Array.from(optionsContainer.textContent.trim().split(""))
      .map((opt) => parseInt(opt, 10))
      .filter((opt) => !isNaN(opt));
    if (options.includes(optionInteger)) {
      options = options.filter((opt) => opt !== optionInteger);
    } else {
      options.push(optionInteger);
      options.sort();
    }
    optionsContainer.textContent = options.join("");
    // update cookie
    let optionsCookie = this.loadOptionsCookie() || {};
    if (!optionsCookie[cell.dataset.row]) optionsCookie[cell.dataset.row] = {};
    optionsCookie[cell.dataset.row][cell.dataset.col] = options;
    document.cookie = "options=" + JSON.stringify(optionsCookie) + "; path=/";
  }

  handleKeyUp(e) {
    const editCell = this.cellTargets.find((cell) =>
      cell.classList.contains("edit-mode"),
    );
    // ignore if no cell is in edit mode, ignore all if the key is not 1-9, backspace/delete, or escape
    if (
      !editCell ||
      (!e.key.match(/[1-9]/) &&
        ["Backspace", "Delete", "Escape"].indexOf(e.key) === -1)
    )
      return;

    // if the cell value div is showing, edit the value, otherwise edit the options
    var editing = editCell
      .querySelector(".cell-value")
      .classList.contains("d-none")
      ? "options"
      : "value";

    if (e.key >= "1" && e.key <= "9") {
      editing === "value"
        ? this.setCellValue(editCell, e.key)
        : this.updateCellOptions(editCell, e.key);
    } else if (e.key === "Backspace" || e.key === "Delete") {
      editing === "value"
        ? this.setCellValue(editCell, "0")
        : (editCell.querySelector(".cell-options").textContent = "");
    } else if (e.key === "Escape") {
      this.clearEditMode();
    }
  }

  clearEditMode() {
    this.cellTargets.forEach((cell) => cell.classList.remove("edit-mode"));
  }

  loadValuesCookie() {
    let valuesCookie = document.cookie
      .split("; ")
      .find((row) => row.startsWith("values="));
    if (!valuesCookie) return;
    const decodedValue = decodeURIComponent(valuesCookie.split("=")[1]);
    return JSON.parse(decodedValue);
  }

  loadOptionsCookie() {
    let optionsCookie = document.cookie
      .split("; ")
      .find((row) => row.startsWith("options="));
    if (!optionsCookie) return;
    const decodedOptions = decodeURIComponent(optionsCookie.split("=")[1]);
    return JSON.parse(decodedOptions);
  }

  clearPuzzle() {
    this.cellTargets.forEach((cell) => {
      this.setCellValue(cell, "0");
      cell.querySelector(".cell-options").textContent = "123456789";
      cell.querySelector(".cell-options").classList.add("d-none");
      cell.querySelector(".cell-value").classList.remove("d-none");
      cell.querySelector(".cell-corner-triangle").classList.remove("d-none");
      this.closeResultCard();
    });
  }

  closeResultCard() {
    this.messageCardTarget.classList.add("d-none");
  }
}
