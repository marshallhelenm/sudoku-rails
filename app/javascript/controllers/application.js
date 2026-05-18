import { Application } from "@hotwired/stimulus";
import "@rails/request.js";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };

const $ = window.jQuery;

if ($) {
  // Delegate to document so the handler still works after Turbo page updates.
  document.addEventListener("DOMContentLoaded", function () {
    if (window.jQuery && $("#fullpage").length) {
      $("#fullpage").fullpage({
        anchors: ["name_card", "projects", "credits"],
      });
    }
  });
  $(document)
    .off("click.projectsNav", ".section-nav-link") // Remove any existing handlers to prevent duplicates
    .on("click.projectsNav", ".section-nav-link", function (event) {
      event.preventDefault();
      const target = $(this).data("target");
      if ($.fn.fullpage && target) {
        console.log(`Moving to ${target} section`);
        $.fn.fullpage.moveTo(target);
      }
    });
}
