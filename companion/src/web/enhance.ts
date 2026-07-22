// Progressive enhancement served as /assets/enhance.js (CSP allows only 'self',
// so no inline handlers). Everything works without it - forms just lose
// auto-submit and confirm dialogs.
export const enhanceJs = `"use strict";
document.querySelectorAll("[data-autosubmit]").forEach(function (el) {
  var form = el.form;
  if (!form) return;
  el.addEventListener("change", function () { form.requestSubmit(); });
  var noscriptButton = form.querySelector("[data-autosubmit-fallback]");
  if (noscriptButton) noscriptButton.hidden = true;
});
document.querySelectorAll("form[data-confirm]").forEach(function (form) {
  form.addEventListener("submit", function (event) {
    if (!window.confirm(form.getAttribute("data-confirm"))) event.preventDefault();
  });
});
`;
