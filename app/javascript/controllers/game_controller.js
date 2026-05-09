import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static targets = ["cell"];

  static values = {
    val: Number,
  };

  connect() {
    // console.log("Game controller connected");
  }

  toggleOptions(e) {
    console.log("Toggling options");
    this.cellTargets.forEach((cell) => {
      if (cell.dataset.value !== "0") return;
      cell.querySelector(".cell-options").classList.toggle("d-none");
      cell.querySelector(".cell-value").classList.toggle("d-none");
    });
    e.target.textContent =
      e.target.textContent === "Show Options" ? "Hide Options" : "Show Options";
  }

  async solve() {
    const response = await patch("/solve_puzzle", {
      responseKind: "turbo-stream",
    });
  }

  async newPuzzle() {
    const response = await patch("/new_puzzle", {
      responseKind: "turbo-stream",
    });
  }

  async generatePuzzles() {
    const response = await patch("/generate_puzzles", {
      responseKind: "turbo-stream",
    });
  }
}
