// Short, predictable help delay rather than the browser's native title timeout.
(() => {
  const tooltip = document.createElement('div');
  tooltip.id = 'ir-help-tooltip';
  tooltip.className = 'ir-help-tooltip';
  tooltip.setAttribute('role', 'tooltip');
  tooltip.hidden = true;
  document.body.append(tooltip);
  let active = null, showTimer = null, hideTimer = null;
  function hide() {
    clearTimeout(showTimer);
    clearTimeout(hideTimer);
    active?.removeAttribute('aria-describedby');
    active = null;
    tooltip.hidden = true;
  }
  function show(target, delay) {
    hide();
    active = target;
    showTimer = setTimeout(() => {
      if (!target.isConnected) return hide();
      tooltip.textContent = target.dataset.help;
      tooltip.hidden = false;
      target.setAttribute('aria-describedby', tooltip.id);
      place(target);
    }, delay);
  }
  function place(target) {
    const bounds = target.getBoundingClientRect();
    const width = tooltip.offsetWidth, height = tooltip.offsetHeight;
    tooltip.style.left = Math.max(8, Math.min(bounds.left, innerWidth - width - 8)) + 'px';
    tooltip.style.top = Math.max(8, bounds.bottom + height + 8 < innerHeight
      ? bounds.bottom + 8 : bounds.top - height - 8) + 'px';
  }
  document.addEventListener('pointerover', event => {
    const target = event.target.closest('[data-help]');
    if (target && target !== active) show(target, 120);
  });
  document.addEventListener('pointerout', event => {
    if (active && event.target.closest('[data-help]') === active
        && !active.contains(event.relatedTarget) && event.relatedTarget !== tooltip)
      hideTimer = setTimeout(hide, 100);
  });
  tooltip.addEventListener('pointerenter', () => clearTimeout(hideTimer));
  tooltip.addEventListener('pointerleave', hide);
  document.addEventListener('focusin', event => {
    const target = event.target.closest('[data-help]');
    if (target) show(target, 0);
  });
  document.addEventListener('focusout', event => {
    if (event.target === active) hide();
  });
  document.addEventListener('keydown', event => { if (event.key === 'Escape') hide(); });
  document.addEventListener('click', hide);
  document.addEventListener('scroll', () => {
    // Focusing a token may scroll it into view after focusin. Move its help
    // rather than hiding it, so the token stays described throughout. If the
    // show timer has not fired yet, it positions the tooltip when it does.
    if (active && active === document.activeElement) {
      const bounds = active.getBoundingClientRect();
      if (bounds.bottom > 0 && bounds.top < innerHeight) {
        if (!tooltip.hidden) place(active);
        return;
      }
    }
    hide();
  }, true);
  window.addEventListener('resize', hide);
  new MutationObserver(() => { if (active && !active.isConnected) hide(); })
    .observe(document.querySelector('#workspace'), { childList: true, subtree: true });
})();
