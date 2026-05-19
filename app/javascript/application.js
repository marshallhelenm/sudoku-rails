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
    controlArrows: true,
    scrollHorizontally: true,
  });
}

function initResponsiveFullpage() {
  const $ = window.jQuery;
  const fullpageRoot = document.getElementById("fullpage");

  if (!$ || !fullpageRoot || !$.fn || !$.fn.fullpage) return;

  $(window).on("resize", () => {
    if ($(window).width() < 768) {
      $.fn.fullpage.setResponsive(true);
    } else {
      $.fn.fullpage.setResponsive(false);
    }
  });
}

document.addEventListener("turbo:load", () => {
  initPortfolioFullpage();
  initResponsiveFullpage();
  toggleProjectViews();
});

window.addEventListener("resize", toggleProjectViews);

function toggleProjectViews() {
  const desktop = document.querySelector(
    ".section.grey-knit-bg .grey-bg.block",
  );
    const mobileWrapper = document.querySelector('.section.grey-knit-bg .mobile-projects-wrapper');
    if (!desktop || !mobileWrapper) return;
    if (window.innerWidth <= 768) {
      desktop.classList.add('d-none');
      mobileWrapper.classList.remove('d-none');
    } else {
      desktop.classList.remove('d-none');
      mobileWrapper.classList.add('d-none');
  }
}

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
});
