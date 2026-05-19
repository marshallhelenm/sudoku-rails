// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

function initPortfolioFullpage() {
  const $ = window.jQuery;
  const fullpageRoot = document.getElementById("fullpage");

  if (!$ || !fullpageRoot || !$.fn || !$.fn.fullpage) return;
  if (document.documentElement.classList.contains("fp-enabled")) return;

  if (window.innerWidth < 769) {
    if ($.fn.fullpage.destroy) {
      $.fn.fullpage.destroy("all");
    }
    document.documentElement.classList.remove("fp-enabled");
    return;
  }
  $("#fullpage").fullpage({
    anchors: ["name_card", "projects", "credits"],
    controlArrows: true,
    scrollHorizontally: true,
  });
}

document.addEventListener("turbo:load", () => {
  initPortfolioFullpage();
});

function handleFullpageOnResize() {
  const $ = window.jQuery;
  const fullpageRoot = document.getElementById("fullpage");
  if (!$ || !fullpageRoot || !$.fn || !$.fn.fullpage) return;
  if (window.innerWidth < 769) {
    if ($.fn.fullpage.destroy) {
      $.fn.fullpage.destroy("all");
    }
    document.documentElement.classList.remove("fp-enabled");
  } else {
    if (!document.documentElement.classList.contains("fp-enabled")) {
      $("#fullpage").fullpage({
        anchors: ["name_card", "projects", "credits"],
        controlArrows: true,
        scrollHorizontally: true,
      });
    }
  }
}

window.addEventListener("resize", () => {
  handleFullpageOnResize();
});

document.addEventListener("click", (event) => {
  const link = event.target.closest(".section-nav-link");
  if (!link) return;

  const $ = window.jQuery;
  const slideDirection = link.dataset.slideDirection;
  const target = link.dataset.target;
  if (!$ || !$.fn || !$.fn.fullpage) return;

  event.preventDefault();

  if (slideDirection === "left") {
    $.fn.fullpage.moveSlideLeft();
    return;
  }

  if (slideDirection === "right") {
    $.fn.fullpage.moveSlideRight();
    return;
  }

  if (!target) return;
  $.fn.fullpage.moveTo(target);
  // Only handle fullPage navigation if fullPage is enabled (desktop)
  if (window.innerWidth < 769) return;
});
