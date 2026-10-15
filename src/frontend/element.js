// h(tag, attributes, ...children): a new element for the user programs scripts (editor.js, programs.js),
// which build their controls only when the user programs setting is on. An `on…` attribute adds that event
// listener, true sets an empty attribute, and false or null leaves it out.
function h(tag, attributes = {}, ...children) {
  const element = document.createElement(tag);
  for (const [name, value] of Object.entries(attributes)) {
    if (name.startsWith("on")) element.addEventListener(name.slice(2), value);
    else if (value === true) element.setAttribute(name, "");
    else if (value !== false && value != null) element.setAttribute(name, value);
  }
  element.append(...children);
  return element;
}
