// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

function initPortfolioFullpage() {
  const $ = window.jQuery;
  const fullpageRoot = document.getElementById("fullpage");

  if (!$ || !fullpageRoot || !$.fn || !$.fn.fullpage) return;
  if (document.documentElement.classList.contains("fp-enabled")) return;

  $("#fullpage").fullpage({
    anchors: ["name_card", "projects", "credits"],
  });
}

document.addEventListener("turbo:load", initPortfolioFullpage);

document.addEventListener("click", (event) => {
  const link = event.target.closest(".section-nav-link");
  if (!link) return;

  const $ = window.jQuery;
  const target = link.dataset.target;
  if (!$ || !$.fn || !$.fn.fullpage || !target) return;

  event.preventDefault();
  $.fn.fullpage.moveTo(target);
});
