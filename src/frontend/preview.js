// E1 navigation mock only. No instruments, answer storage, identifiers, or writes.
// This build is preview-only; E6 must supply server-controlled release modes.
(() => {
  const preview = document.body.dataset.studyMode === "preview";
  const screen = document.querySelector("#study-screen");
  const workspace = document.querySelector("#workspace-shell");
  const progress = document.querySelector("#study-progress");
  const layout = document.querySelector("#journey-layout");
  const routes = ["/study", "/study/pre", "/study/tasks/preview", "/study/post", "/study/complete"];
  const names = ["Information", "Pre-survey", "Tasks", "Post-survey", "Receipt"];
  let unlocked = 0;
  const button = (action, text, primary = false) => `<button type="button" data-action="${action}"${primary ? ' class="primary"' : ''}>${text}</button>`;
  const heading = text => `<h2 id="route-heading" tabindex="-1">${text}</h2>`;
  const sample = label => `<label class="sample-answer">${label}<textarea rows="3" readonly aria-describedby="placeholder-note">Synthetic example only — no response is collected.</textarea></label><p id="placeholder-note" class="form-note">Form layout placeholder. The original instrument will be implemented in a later step.</p>`;
  function go(route, replace = false) {
    if (replace || location.hash === `#${route}`) {
      history.replaceState(null, "", `#${route}`);
      render();
    } else location.hash = route;
  }
  function reset(route = "/study") {
    unlocked = 0;
    go(route, true);
  }
  function render() {
    const route = location.hash.slice(1) || "/explore";
    const explore = route === "/explore";
    const exited = route === "/study/declined" || route === "/study/stopped";
    const index = routes.indexOf(route);
    if (!preview && !explore) return go("/explore", true);
    if (!explore && !exited && (index < 0 || index > unlocked)) {
      return go(routes[unlocked], true);
    }
    screen.hidden = explore;
    workspace.hidden = !explore && index !== 2;
    progress.hidden = explore || exited;
    document.querySelector("#explore-heading").hidden = !explore;
    document.querySelector(".skip-link").href = explore ? "#explore-heading" : "#route-heading";
    layout.classList.toggle("with-task", index === 2);
    progress.innerHTML = `<ol>${names.map((name, n) => `<li${n === index ? ' aria-current="step"' : ''}>${n + 1}. ${n <= unlocked ? `<a href="#${routes[n]}">${name}</a>` : name}</li>`).join("")}</ol>`;
    if (explore) {
      document.title = "Explore · irexplorer";
      document.querySelector("#explore-heading").focus();
      return;
    }
    let content;
    if (exited) {
      content = heading(route.endsWith("declined") ? "Preview declined" : "Preview stopped") + `<p>No response record was created. Preview progress has been cleared.</p>${button("restart", "Start a new preview", true)} <a href="#/explore">Explore curated artefacts</a>`;
    } else if (index === 0) {
      content = heading("Information and consent") + `<p class="eyebrow">Screen 1 of 5 · Preview only</p><p>This space will present the study information, data policy, contacts, and consent acknowledgements. Participant wording is pending implementation and review.</p><p>This is a synthetic walkthrough, not an invitation to participate. The checkbox below only unlocks the layout preview.</p><label class="acknowledgement"><input id="preview-ack" type="checkbox" ${unlocked > 0 ? 'checked' : ''}> I understand that this is a synthetic preview and no answers will be saved.</label><div class="screen-actions">${button("start", "Continue to pre-survey", true)}${button("decline", "Decline and exit")}</div>`;
    } else if (index === 1) {
      content = heading("Pre-survey") + `<p class="eyebrow">Screen 2 of 5 · Form placeholder</p><p>P1–P13 will appear here with their original wording, scales, and optionality. This preview does not ask or validate those questions.</p>${sample("Example response layout")}<div class="screen-actions">${button("next", "Continue to preview task", true)}<a href="#/study">Back to information</a></div>`;
    } else if (index === 2) {
      content = heading("Preview task") + `<p class="eyebrow">Screen 3 of 5 · Synthetic goal</p><p><strong>Goal:</strong> Try comparing a curated example using the two panes.</p><details class="task-details" open><summary>Instructions and response placeholder</summary><p>Choose a file, then change the state or IR/CFG view in either pane. Select an IR instruction or CFG block to inspect its recorded link.</p><p>This is not T0–T6. The ordered study tasks and timing arrive in E5.</p>${sample("Preview response area")}</details><div class="screen-actions">${button("next", "Continue to post-survey", true)}<a href="#/study/pre">Back to pre-survey</a><a href="#workspace">Go to comparison</a></div>`;
    } else if (index === 3) {
      content = heading("Post-survey") + `<p class="eyebrow">Screen 4 of 5 · Form placeholder</p><p>Q1–Q20 will appear here with the original response options, including separate not-applicable choices.</p>${sample("Example comments layout")}<p>No submission is available in this preview. The next button shows a simulated receipt without sending a request.</p><div class="screen-actions">${button("receipt", "Show simulated receipt", true)}<a href="#/study/tasks/preview">Back to preview task</a></div>`;
    } else {
      content = heading("Simulated receipt") + `<p class="eyebrow">Screen 5 of 5 · Preview only</p><p><strong>Nothing was submitted or saved.</strong> This previews the position of the receipt screen; durable acknowledgement and retry behaviour arrive in E6.</p>${button("restart", "Restart preview", true)} <a href="#/explore">Explore curated artefacts</a>`;
    }
    screen.innerHTML = content + (!exited && index < 4 && unlocked > 0 ? `<div class="study-utilities"><a href="#/study">Information</a>${button("stop", "Stop and discard preview")}</div>` : "");
    const ack = screen.querySelector("#preview-ack");
    if (ack) {
      const start = screen.querySelector('[data-action="start"]');
      start.disabled = !ack.checked;
      ack.addEventListener("change", () => { start.disabled = !ack.checked; });
    }
    // Narrow layouts keep the goal/actions visible and let instructions expand.
    if (index === 2 && matchMedia("(max-width: 1100px)").matches) screen.querySelector("details").open = false;
    document.title = `${screen.querySelector("h2").textContent} · irexplorer preview`;
    screen.querySelector("h2").focus();
    window.scrollTo(0, 0);
  }
  screen.addEventListener("click", event => {
    const action = event.target.closest("[data-action]")?.dataset.action;
    if (!action || !preview) return;
    const index = routes.indexOf(location.hash.slice(1));
    if (action === "start" && screen.querySelector("#preview-ack")?.checked) {
      unlocked = Math.max(unlocked, 1); go(routes[1]);
    } else if (action === "next" && (index === 1 || index === 2)) {
      unlocked = Math.max(unlocked, index + 1); go(routes[index + 1]);
    } else if (action === "receipt" && index === 3) {
      unlocked = 4; go(routes[4]);
    } else if (action === "decline" || action === "stop") reset(`/study/${action === "decline" ? "declined" : "stopped"}`);
    else if (action === "restart") reset();
  });
  document.querySelector("#preview-controls").hidden = !preview;
  document.querySelector("#preview-reset").addEventListener("click", () => { if (preview) reset(); });
  // In-page focus links must not be interpreted as study routes.
  document.addEventListener("click", event => {
    const link = event.target.closest('a[href^="#"]');
    const target = link?.getAttribute("href");
    if (!target || target.startsWith("#/")) return;
    const element = document.getElementById(target.slice(1));
    if (!element) return;
    event.preventDefault();
    element.tabIndex = -1;
    element.focus();
    element.scrollIntoView({ block: "start" });
  });
  window.addEventListener("hashchange", render);
  render();
})();
